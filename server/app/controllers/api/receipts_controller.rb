# frozen_string_literal: true

module Api
  # PDF receipts / invoices for completed rentals (customer self-service and the
  # counter settlement flow).
  class ReceiptsController < BaseController
    before_action :authorize_receipts!

    # GET /api/:organization/receipts/:rental_id
    def show
      rental = find_rental!(params[:rental_id])
      ensure_own_rental!(rental)

      pdf = ReceiptPdfService.new(rental).render
      send_data pdf, filename: "driveflow-receipt-#{rental.reservation_number}.pdf",
                     type: 'application/pdf', disposition: 'inline'
    end

    # GET /api/:organization/receipts/:rental_id/invoice
    def invoice
      rental = find_rental!(params[:rental_id])
      ensure_own_rental!(rental)

      pdf = ReceiptPdfService.new(rental).render
      send_data pdf, filename: "driveflow-invoice-#{rental.reservation_number}.pdf",
                     type: 'application/pdf', disposition: 'attachment'
    end

    # GET /api/:organization/receipts
    def index
      rentals = scoped(Rental).where(status: 'completed').order(actual_return_datetime: :desc).limit(50)
      if current_user.role_slug_for_validation(current_organization) == 'customer'
        profile_ids = current_user.customer_profiles.where(organization_id: current_organization.id).pluck(:id)
        rentals = rentals.where(customer_profile_id: profile_ids)
      end

      render json: {
        data: rentals.map do |rental|
          {
            'id' => rental.id, 'rental_id' => rental.id,
            'reservation_number' => rental.reservation_number,
            'customer' => rental.customer_profile&.full_name,
            'total_charges_amount' => rental.total_charges_amount.to_d.to_f,
            'balance_owed_amount' => rental.balance_owed_amount.to_d.to_f,
            'deposit_status' => rental.deposit_status,
            'issued_at' => rental.actual_return_datetime&.iso8601,
            'receipt_url' => "/api/#{current_organization.slug}/receipts/#{rental.id}"
          }
        end
      }
    end

    private

    def authorize_receipts!
      return true if permitted?('rentals', 'show') || permitted?('rentals', 'index')

      render json: { message: 'This action is unauthorized.' }, status: :forbidden
      false
    end

    # A customer may only pull their own receipts.
    def ensure_own_rental!(rental)
      return unless current_user.role_slug_for_validation(current_organization) == 'customer'

      own_ids = current_user.customer_profiles.where(organization_id: current_organization.id).pluck(:id)
      return if own_ids.include?(rental.customer_profile_id)

      render json: { message: 'This action is unauthorized.' }, status: :forbidden
    end
  end
end
