# frozen_string_literal: true

module Api
  # Non-CRUD rental operations: settlement preview, comparison, notifications,
  # extensions, escalation and CSV export.
  class RentalsController < BaseController
    before_action :authorize_permission_for_read, only: %i[settlement_preview inspection_comparison receipt csv]
    before_action :find_rental_for_action, only: %i[notify notes escalate extend settlement_preview inspection_comparison receipt finalize]

    # GET /api/:organization/rentals/:id/settlement_preview
    def settlement_preview
      calculator = RentalSettlementCalculator.new(@rental)
      render json: { settlement: calculator.summary, lines: calculator.lines.map { |l| l.transform_keys(&:to_s) } }
    end

    def find_checkout_inspection
      if params[:inspection_id].present?
        @rental.inspections.kept.find_by(id: params[:inspection_id])
      else
        @rental.inspections.kept.find_by(inspection_type: 'check_out')
      end
    end

    # GET /api/:organization/rentals/:id/inspection_comparison
    def inspection_comparison
      departure = @rental.inspections.kept.find_by(inspection_type: 'check_out')
      arrival = @rental.inspections.kept.find_by(inspection_type: 'check_in')

      render json: {
        rental: serialize_rental(@rental),
        departure: serialize_inspection(departure),
        return: serialize_inspection(arrival),
        damage: {
          'pre_existing' => damage_for(departure),
          'new' => damage_for(arrival, new_only: true)
        },
        deltas: comparison_deltas(departure, arrival)
      }
    end

    # POST /api/:organization/rentals/:id/notify
    def notify
      return unless authorize_permission!('rentals', 'update')

      result = NotificationService.new(@rental).deliver_return_urgency(channel: params[:channel].presence || 'sms+email')
      render json: { message: 'Return urgency notice dispatched', notification: result,
                     rental: serialize_rental(@rental.reload) }, status: :created
    end

    # POST /api/:organization/rentals/:id/notes
    def notes
      return unless authorize_permission!('rentals', 'update')

      body = params[:body].presence || params[:note].presence
      return render(json: { errors: { body: ['is required'] } }, status: :unprocessable_entity) if body.blank?

      stamped = "[#{Time.current.utc.iso8601}] #{body}"
      @rental.update!(notes: [@rental.notes, stamped].compact_blank.join("\n"))

      render json: { note: stamped, rental: serialize_rental(@rental.reload) }, status: :created
    end

    # POST /api/:organization/rentals/:id/escalate
    def escalate
      return unless authorize_permission!('rentals', 'update')

      reason = params[:reason].presence || 'Unreturned asset flagged for recovery'
      @rental.update!(
        escalated_for_recovery: true,
        notes: [@rental.notes, "[#{Time.current.utc.iso8601}] ESCALATED: #{reason}"].compact_blank.join("\n")
      )

      render json: { message: 'Case escalated for recovery', recovery_flagged: true,
                     rental: serialize_rental(@rental.reload) }, status: :created
    end

    # POST /api/:organization/rentals/:id/extend
    # Approving an extension is a revenue-affecting decision, so it is gated on
    # the dedicated `rentals.extend` permission (fleet managers), not plain
    # rentals.update (AC-84 / AC-89).
    def extend
      return unless authorize_permission!('rentals', 'extend')

      new_return = params[:scheduled_return_datetime].presence
      rental = RentalExtensionService.new(@rental, new_return_datetime: Time.zone.parse(new_return.to_s)).call

      render json: { message: 'Extension approved', rental: serialize_rental(rental) }, status: :ok
    end

    # POST /api/:organization/rentals/:id/finalize
    # Completes the counter handover after the renter signs: stamps the check-out
    # inspection with the signature, activates the rental and flips the vehicle
    # to `rented`.
    def finalize
      return unless authorize_permission!('rentals', 'update')

      inspection = find_checkout_inspection
      return render(json: { errors: { inspection: ['check-out inspection not found'] } }, status: :unprocessable_entity) if inspection.nil?

      signed_at = params[:customer_signature_timestamp].presence || Time.current.iso8601
      inspection.update!(
        customer_signature_url: params[:customer_signature_url].presence || inspection.customer_signature_url,
        customer_signature_timestamp: Time.zone.parse(signed_at.to_s) || Time.current,
        notes: [inspection.notes, params[:notes].presence].compact_blank.join("\n").presence
      )

      ActiveRecord::Base.transaction do
        @rental.update!(
          status: 'active',
          agreement_signed_at: Time.current,
          agreement_signed_by_name: params[:signed_by_name].presence ||
                                    @rental.customer_profile&.full_name,
          initial_odometer: @rental.initial_odometer || inspection.odometer_reading,
          initial_fuel_percentage: @rental.initial_fuel_percentage || inspection.fuel_percentage
        )
        @rental.vehicle&.update_columns(status: 'rented', updated_at: Time.current)
      end

      AgreementMailer.executed_agreement(@rental.reload, pdf: ContractPdfService.new(@rental).render).deliver_later

      render json: {
        message: 'Handover complete',
        rental: serialize_rental(@rental.reload),
        inspection: serialize_inspection(inspection.reload)
      }, status: :ok
    end

    # GET /api/:organization/rentals/:id/receipt
    def receipt
      pdf = ReceiptPdfService.new(@rental).render
      send_data pdf, filename: "driveflow-receipt-#{@rental.reservation_number}.pdf",
                     type: 'application/pdf', disposition: 'attachment'
    end

    # GET /api/:organization/rentals/export.csv
    def csv
      require 'csv'
      rentals = scoped(Rental).order(:reservation_number)

      body = CSV.generate(headers: true) do |csv|
        csv << %w[reservation_number status customer vehicle pickup return total charges paid balance overdue_hours late_fee]
        rentals.each do |rental|
          csv << [
            rental.reservation_number, rental.status,
            rental.customer_profile&.full_name, rental.vehicle&.license_plate,
            rental.pickup_datetime, rental.scheduled_return_datetime,
            rental.total_charges_amount.to_f, rental.total_paid_amount.to_f,
            rental.balance_owed_amount.to_f, rental.billable_overdue_hours,
            rental.late_fee_accrued.to_f
          ]
        end
      end

      send_data body, filename: 'driveflow-active-rentals.csv', type: 'text/csv', disposition: 'attachment'
    end

    private

    def authorize_permission_for_read
      authorize_permission!('rentals', 'show')
    end

    def find_rental_for_action
      @rental = find_rental!(params[:id])
    end

    def serialize_rental(rental)
      rental.as_rhino_json.merge(rental.rhino_computed_attributes)
    end

    def serialize_inspection(inspection)
      return nil if inspection.nil?

      inspection.as_rhino_json.merge(inspection.rhino_computed_attributes).merge(
        'attachments' => attachment_payload(inspection)
      )
    end

    def attachment_payload(inspection)
      inspection.damage_records.kept.map do |record|
        {
          'id' => record.id, 'panel_location' => record.panel_location,
          'severity' => record.severity, 'photo_url' => record.photo_url,
          'is_pre_existing' => record.is_pre_existing, 'captured_angle' => record.captured_angle,
          'photo_taken_at' => record.photo_taken_at&.iso8601, 'dimensions' => record.dimensions
        }
      end
    end

    def damage_for(inspection, new_only: false)
      return [] if inspection.nil?

      scope = inspection.damage_records.kept
      scope = scope.where(is_pre_existing: false) if new_only
      scope.map { |r| { 'panel_location' => r.panel_location, 'severity' => r.severity,
                        'photo_url' => r.photo_url, 'description' => r.description } }
    end

    def comparison_deltas(departure, arrival)
      return {} if departure.nil? || arrival.nil?

      {
        'odometer_delta' => arrival.odometer_reading.to_i - departure.odometer_reading.to_i,
        'fuel_variance_percentage' => departure.fuel_percentage.to_i - arrival.fuel_percentage.to_i,
        'new_damage_count' => arrival.damage_records.kept.where(is_pre_existing: false).count
      }
    end
  end
end
