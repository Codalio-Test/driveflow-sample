# frozen_string_literal: true

module Api
  # Public availability search: matching vehicle categories for a pickup /
  # return window at a branch, with the live rentable vehicle count.
  class AvailabilityController < PublicController
    def index
      window = requested_window
      return if performed?

      categories = public_scope(VehicleCategory).order(:base_daily_rate)
      categories = categories.where(id: Array(params[:category_id]).map(&:to_i)) if params[:category_id].present?

      data = categories.map do |category|
        vehicles = public_scope(Vehicle).where(vehicle_category_id: category.id)
        vehicles = vehicles.where(location_id: params[:location_id]) if params[:location_id].present?
        available = if window
                      vehicles.where(status: 'available').reject { |v| overlapping?(v, window) }
                    else
                      vehicles.where(status: 'available').to_a
                    end

        category.rhino_computed_attributes.merge(
          'id' => category.id,
          'name' => category.name,
          'code' => category.code,
          'description' => category.description,
          'base_daily_rate' => category.base_daily_rate.to_f,
          'daily_rate' => RateCalculator.new(category).daily_rate(window&.begin&.to_date || Date.current).to_f,
          'security_deposit_amount' => category.security_deposit_amount.to_f,
          'passenger_capacity' => category.passenger_capacity,
          'baggage_capacity' => category.baggage_capacity,
          'transmission' => category.transmission,
          'available_count' => available.size,
          'available' => available.size.positive?
        )
      end

      render json: {
        data: data,
        meta: {
          pickup_datetime: window&.begin&.iso8601,
          return_datetime: window&.end&.iso8601,
          organization: current_organization.slug
        }
      }
    end

    private

    # Accepts the date keys the SPA uses (`scheduled_return_datetime` mirrors
    # the rentals payload) as well as the shorter funnel aliases.
    def requested_window
      pickup = parse_time(params[:pickup_datetime] || params[:pickup])
      dropoff = parse_time(params[:return_datetime] || params[:scheduled_return_datetime] ||
                           params[:return] || params[:dropoff])

      # No window supplied → browse the whole catalogue unfiltered.
      return nil if pickup.blank? || dropoff.blank?

      if dropoff <= pickup
        render json: {
          errors: { scheduled_return_datetime: ['must be after the pickup time'] },
          message: 'Invalid date range'
        }, status: :unprocessable_entity
        return nil
      end

      # A return date in the past is not a bookable reservation (AC-4).
      if dropoff <= Time.current
        render json: {
          errors: { scheduled_return_datetime: ['must be in the future'] },
          message: 'Invalid date range'
        }, status: :unprocessable_entity
        return nil
      end

      pickup..dropoff
    end

    def parse_time(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    # A vehicle is unavailable when it already has a live contract overlapping
    # the requested window.
    def overlapping?(vehicle, window)
      Rental.where(vehicle_id: vehicle.id, status: %w[reserved confirmed active overdue])
            .where('pickup_datetime < ? AND scheduled_return_datetime > ?', window.end, window.begin)
            .exists?
    end
  end
end
