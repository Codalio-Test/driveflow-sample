# frozen_string_literal: true

module Api
  # Fleet schedule matrix: one row per vehicle with the day-by-day occupancy
  # blocks the AdminFleetMatrix timeline renders.
  class FleetController < BaseController
    before_action :authorize_fleet!

    # GET /api/:organization/fleet_matrix?from=2026-01-01&to=2026-01-14
    def matrix
      from = parse_date(params[:from]) || (Date.current - 3)
      to = parse_date(params[:to]) || (from + 13)
      to = from + 60 if (to - from).to_i > 60

      vehicles = scoped(Vehicle).order(:license_plate)
      rentals = scoped(Rental)
                .where(status: %w[reserved confirmed active overdue])
                .where('pickup_datetime <= ? AND scheduled_return_datetime >= ?', to.end_of_day, from.beginning_of_day)
                .includes(:customer_profile)

      by_vehicle = rentals.group_by(&:vehicle_id)

      rows = vehicles.map do |vehicle|
        blocks = (by_vehicle[vehicle.id] || []).map do |rental|
          {
            'rental_id' => rental.id,
            'reservation_number' => rental.reservation_number,
            'customer' => rental.customer_profile&.full_name,
            'status' => rental.status,
            'start' => rental.pickup_datetime&.iso8601,
            'end' => rental.scheduled_return_datetime&.iso8601,
            'start_day' => rental.pickup_datetime&.to_date&.iso8601,
            'end_day' => rental.scheduled_return_datetime&.to_date&.iso8601,
            'overdue' => rental.beyond_grace?
          }
        end

        {
          'id' => vehicle.id,
          'name' => vehicle.display_name,
          'plate' => vehicle.license_plate,
          'location' => vehicle.location&.name,
          'status' => vehicle.status,
          'category' => vehicle.vehicle_category&.name,
          'current_odometer' => vehicle.current_odometer,
          'health' => vehicle.health_percentage,
          'miles' => "#{vehicle.current_odometer.to_i} mi",
          'service_due' => vehicle.service_due?,
          'blocks' => blocks
        }
      end

      render json: {
        'from' => from.iso8601,
        'to' => to.iso8601,
        'days' => (from..to).map(&:iso8601),
        'vehicles' => rows,
        'summary' => Vehicle::STATUSES.index_with { |status| vehicles.where(status: status).count }
      }
    end

    private

    # The schedule matrix is an administrative surface: it exposes the whole
    # fleet's occupancy, so it is gated on the dedicated `fleet_matrix.index`
    # permission (granted to fleet managers) rather than plain vehicle reads.
    def authorize_fleet!
      return true if permitted?('fleet_matrix', 'index')

      render json: { message: 'This action is unauthorized.' }, status: :forbidden
      false
    end

    def parse_date(value)
      return nil if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end
