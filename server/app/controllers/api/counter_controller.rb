# frozen_string_literal: true

module Api
  # Counter queues: the departures dispatch board and the returns inbound list,
  # each pre-computed with readiness / grace flags so the tablet renders in one
  # round-trip.
  class CounterController < BaseController
    before_action :authorize_counter!

    # GET /api/:organization/counter/departures
    def departures
      today = Time.zone.today
      rentals = scoped(Rental)
                .where(status: %w[reserved confirmed active])
                .where(pickup_datetime: today.beginning_of_day..(today + 7).end_of_day)
                .order(:pickup_datetime)

      data = rentals.map do |rental|
        rental.as_rhino_json.merge(rental.rhino_computed_attributes).merge(
          'prep_ready' => prep_ready?(rental),
          'deposit_secured' => rental.deposit_hold_total.positive?,
          'agreement_signed' => rental.agreement_signed_at.present?,
          'inspection_complete' => rental.inspections.kept.where(inspection_type: 'check_out').exists?,
          'assigned_vehicle' => rental.vehicle ? { 'id' => rental.vehicle.id, 'plate' => rental.vehicle.license_plate,
                                                   'name' => rental.vehicle.display_name } : nil
        )
      end

      render json: {
        data: data,
        kpis: {
          'pending' => data.count { |r| !r['prep_ready'] },
          'ready' => data.count { |r| r['prep_ready'] },
          'today' => data.count { |r| Time.zone.parse(r['pickup_datetime'].to_s).to_date == today },
          'unsecured_deposits' => data.count { |r| !r['deposit_secured'] }
        }
      }
    end

    # GET /api/:organization/counter/returns
    def returns
      rentals = scoped(Rental)
                .where(status: %w[active overdue confirmed])
                .where('scheduled_return_datetime <= ?', 2.days.from_now)
                .order(:scheduled_return_datetime)

      data = rentals.map do |rental|
        rental.as_rhino_json.merge(rental.rhino_computed_attributes).merge(
          'grace_expired' => rental.beyond_grace?,
          'within_grace' => !rental.beyond_grace? && rental.scheduled_return_datetime.present? && Time.current > rental.scheduled_return_datetime,
          'minutes_until_due' => rental.scheduled_return_datetime ? ((rental.scheduled_return_datetime - Time.current) / 60).round : nil
        )
      end

      render json: {
        data: data,
        kpis: {
          'arrived' => data.count { |r| r['status'] == 'completed' },
          'due' => data.count { |r| r['status'] == 'active' },
          'overdue' => data.count { |r| r['status'] == 'overdue' },
          'grace_expired' => data.count { |r| r['grace_expired'] }
        }
      }
    end

    # GET /api/:organization/counter/lookup?q=DF-1234
    def lookup
      query = (params[:q].presence || params[:query].presence || params[:search].presence).to_s.strip
      return render(json: { data: [] }) if query.blank?

      rentals = scoped(Rental)
                .left_joins(:vehicle, :customer_profile)
                .where(
                  'rentals.reservation_number ILIKE :q OR vehicles.license_plate ILIKE :q OR ' \
                  'vehicles.vin ILIKE :q OR customer_profiles.full_name ILIKE :q',
                  q: "%#{query}%"
                )
                .limit(10)

      render json: {
        data: rentals.map { |r| r.as_rhino_json.merge(r.rhino_computed_attributes) }
      }
    end

    private

    # The queues expose the whole day's dispatch board, so each action is gated
    # on its own counter permission rather than a plain rentals read.
    def authorize_counter!
      action = action_name == 'returns' ? 'returns' : (action_name == 'lookup' ? 'lookup' : 'departures')
      return true if permitted?('counter', action) || permitted?('counter', 'departures')

      render json: { message: 'This action is unauthorized.' }, status: :forbidden
      false
    end

    def prep_ready?(rental)
      rental.vehicle_id.present? && rental.deposit_hold_total.positive?
    end
  end
end
