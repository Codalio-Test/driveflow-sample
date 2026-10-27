# frozen_string_literal: true

module Api
  # Digital rental agreement: the terms payload rendered on the tablet, the
  # signature capture, and the handover completion that flips the vehicle to
  # `rented` and emails the executed PDF.
  class AgreementsController < BaseController
    # GET /api/:organization/agreements?rental_id=...  (or /rentals/:id/agreement)
    def show
      return unless authorize_permission!('agreements', 'show')

      rental = find_rental!(params[:rental_id] || params[:id])
      render json: { agreement: agreement_payload(rental) }
    end

    # POST /api/:organization/agreements/sign
    def sign
      return unless authorize_permission!('agreements', 'sign')

      rental = find_rental!(params[:rental_id] || params[:id])
      signature = params[:signature_url].presence || params[:signature_data_url].presence ||
                  params[:signature].presence
      inspection = rental.inspections.kept.find_by(inspection_type: 'check_out')

      ActiveRecord::Base.transaction do
        rental.update!(
          agreement_signed_at: Time.current,
          agreement_signed_by_name: params[:signed_by_name].presence || rental.customer_profile&.full_name
        )

        if inspection
          inspection.update!(
            customer_signature_url: signature,
            customer_signature_timestamp: Time.current
          )
        end
      end

      pdf = ContractPdfService.new(rental.reload).render
      AgreementMailer.executed_agreement(rental, pdf: pdf).deliver_later

      render json: {
        message: 'Agreement signed',
        rental: serialize_rental(rental.reload),
        signature_timestamp: rental.agreement_signed_at&.utc&.iso8601,
        contract_hash: ContractPdfService.new(rental).digest
      }, status: :created
    end

    # POST /api/:organization/agreements/complete_handover
    def complete_handover
      return unless authorize_permission!('agreements', 'complete_handover')

      rental = find_rental!(params[:rental_id] || params[:id])

      unless rental.agreement_signed_at.present?
        return render json: {
          errors: { agreement: ['must be signed before the keys can be released'] },
          message: 'Signed agreement required before handover'
        }, status: :unprocessable_entity
      end

      unless rental.deposit_hold_total.positive?
        return render json: {
          errors: { deposit: ['an active pre-authorization hold is required before handover'] },
          message: 'Deposit pre-authorization required before handover'
        }, status: :unprocessable_entity
      end

      ActiveRecord::Base.transaction do
        rental.update!(status: 'active')
        rental.vehicle&.update_columns(status: 'rented', updated_at: Time.current)
      end

      render json: {
        message: 'Handover complete',
        rental: serialize_rental(rental.reload),
        vehicle_status: rental.vehicle&.status
      }, status: :ok
    end

    private

    def agreement_payload(rental)
      category = rental.vehicle_category
      calculator = RentalSettlementCalculator.new(rental)
      {
        'rental_id' => rental.id,
        'reservation_number' => rental.reservation_number,
        'renter' => {
          'full_name' => rental.customer_profile&.full_name,
          'email' => rental.customer_profile&.email,
          'license_number' => rental.customer_profile&.license_number,
          'license_state' => rental.customer_profile&.license_state,
          'license_expiry_date' => rental.customer_profile&.license_expiry_date
        },
        'vehicle' => {
          'category' => category&.name,
          'label' => rental.vehicle ? "#{rental.vehicle.display_name} · #{rental.vehicle.license_plate}" : nil,
          'plate' => rental.vehicle&.license_plate
        },
        'rates' => {
          'daily_rate' => RateCalculator.new(category).daily_rate.to_f,
          'scheduled_duration_days' => rental.scheduled_duration_days,
          'protection_tier' => rental.protection_tier,
          'protection_price_per_day' => BookingChargeService::PROTECTION_TIERS.fetch(rental.protection_tier, { price_per_day: 0 })[:price_per_day].to_f
        },
        'deposit' => {
          'amount' => (rental.deposit_hold_total.positive? ? rental.deposit_hold_total : category&.security_deposit_amount || 0).to_d.to_f,
          'status' => rental.deposit_status
        },
        'charges' => rental.rental_charges.kept.order(:id).map do |charge|
          { 'charge_type' => charge.charge_type, 'description' => charge.description, 'amount' => charge.amount.to_d.to_f }
        end,
        'total_charges_amount' => rental.total_charges_amount.to_d.to_f,
        'condition_summary' => {
          'departure_odometer' => rental.initial_odometer,
          'departure_fuel_percentage' => rental.initial_fuel_percentage,
          'pinned_blemishes' => rental.inspections.kept.where(inspection_type: 'check_out')
                                               .sum { |i| i.damage_records.kept.count }
        },
        'late_policy' => {
          'grace_minutes' => Rental::LATE_GRACE_MINUTES,
          'hourly_fee' => rental.late_hourly_rate.to_f,
          'daily_cap' => calculator.daily_rate_cap.to_f
        },
        'signed_at' => rental.agreement_signed_at&.utc&.iso8601,
        'signed' => rental.agreement_signed_at.present?
      }
    end

    def serialize_rental(rental)
      rental.as_rhino_json.merge(rental.rhino_computed_attributes)
    end
  end
end
