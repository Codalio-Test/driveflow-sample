# frozen_string_literal: true

module Api
  # Accounts-receivable view: contracts whose final charges exceeded the
  # security deposit hold, with the customer's on-file Stripe token.
  class BillingController < BaseController
    before_action :authorize_billing!

    # GET /api/:organization/billing/outstanding
    def outstanding
      rentals = scoped_scope(Rental, 'with_balance_owed').order(balance_owed_amount: :desc)

      data = rentals.map do |rental|
        {
          'id' => rental.id,
          'reservation_number' => rental.reservation_number,
          'customer' => rental.customer_profile&.full_name,
          'customer_profile_id' => rental.customer_profile_id,
          'stripe_customer_token' => rental.customer_profile&.stripe_customer_token,
          'balance_owed_amount' => rental.balance_owed_amount.to_d.to_f,
          'total_charges_amount' => rental.total_charges_amount.to_d.to_f,
          'deposit_held' => rental.deposit_hold_total.to_f,
          'status' => rental.status,
          'due' => rental.rhino_computed_attributes['due'],
          'card_last4' => rental.customer_profile&.card_last4
        }
      end

      render json: {
        data: data,
        total_outstanding: data.sum { |row| row['balance_owed_amount'] }.round(2),
        count: data.size
      }
    end

    private

    # Back-office accounts-receivable reconciliation is a fleet-manager surface
    # (AC-69). It must NOT be reachable through the plain `rentals.index`
    # permission — a renter legitimately holds that for /account/bookings.
    def authorize_billing!
      return true if permitted?('billing', 'outstanding')

      render json: { message: 'This action is unauthorized.' }, status: :forbidden
      false
    end
  end
end
