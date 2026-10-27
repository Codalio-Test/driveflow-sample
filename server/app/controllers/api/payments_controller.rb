# frozen_string_literal: true

module Api
  # Security-deposit lifecycle and balance recovery.
  #
  # Every action is gated on the cross-resource deposit permission
  # (payments.store + rentals.update) and runs inside a transaction so a hold,
  # capture and release can never half-apply.
  class PaymentsController < BaseController
    before_action :authorize_deposit!, only: %i[hold expand_hold capture release settle charge_balance refund]

    # POST /api/:organization/payments/hold
    def hold
      rental = find_rental!(params[:rental_id])
      amount = params[:amount].presence&.to_d || rental.vehicle_category.security_deposit_amount

      payment = stripe_service.hold(
        rental: rental,
        amount: amount,
        payment_method: params[:payment_method],
        last4: params[:payment_method_last4]
      )

      if params[:status_after].present?
        rental.update!(status: params[:status_after])
      end

      render json: {
        payment: serialize_payment(payment),
        rental: serialize_rental(rental.reload),
        message: 'Security deposit secured'
      }, status: :created
    rescue StripePaymentService::PaymentError => e
      render_decline(e)
    end

    # POST /api/:organization/payments/expand_hold
    def expand_hold
      rental = find_rental!(params[:rental_id])
      amount = params[:amount].presence&.to_d
      return render(json: { errors: { amount: ['is required'] } }, status: :unprocessable_entity) if amount.blank?

      payment = stripe_service.expand_hold(
        rental: rental, amount: amount,
        payment_method: params[:payment_method], last4: params[:payment_method_last4]
      )

      render json: { payment: serialize_payment(payment), rental: serialize_rental(rental.reload) }, status: :created
    rescue StripePaymentService::PaymentError => e
      rental.update_columns(escalated_for_recovery: true, updated_at: Time.current)
      render_decline(e, extra: { escalated: true, recovery_flagged: true })
    end

    # POST /api/:organization/payments/capture
    def capture
      rental = find_rental!(params[:rental_id])
      amount = params[:amount].to_d
      result = stripe_service.settle(rental: rental, capture_amount: amount, release_amount: params[:release_amount]&.to_d)

      render json: settle_payload(rental, result), status: :created
    rescue StripePaymentService::PaymentError => e
      render_decline(e)
    end

    # POST /api/:organization/payments/release
    def release
      rental = find_rental!(params[:rental_id])
      result = stripe_service.release(rental: rental)

      render json: {
        rental: serialize_rental(rental.reload),
        payment: result[:release] ? serialize_payment(result[:release]) : nil,
        message: 'Deposit released'
      }, status: :created
    rescue StripePaymentService::PaymentError => e
      render_decline(e)
    end

    # POST /api/:organization/payments/settle
    # Atomically captures assessed charges and releases the difference.
    def settle
      rental = find_rental!(params[:rental_id])
      inspection = rental.inspections.kept.find_by(id: params[:inspection_id]) ||
                   rental.inspections.kept.find_by(inspection_type: 'check_in')

      calculator = RentalSettlementCalculator.new(rental, return_inspection: inspection)
      calculator.persist!

      result = stripe_service.settle(
        rental: rental.reload,
        capture_amount: calculator.capture_amount,
        release_amount: calculator.release_amount
      )

      finalize_settlement!(rental, calculator)
      render json: settle_payload(rental.reload, result, calculator), status: :created
    rescue StripePaymentService::PaymentError => e
      render_decline(e)
    end

    # POST /api/:organization/payments/charge_balance
    def charge_balance
      rental = find_rental!(params[:rental_id])
      payment = stripe_service.charge_balance(
        rental: rental,
        amount: params[:amount].presence&.to_d,
        payment_method: params[:payment_method],
        last4: params[:payment_method_last4]
      )

      render json: { payment: serialize_payment(payment), rental: serialize_rental(rental.reload) }, status: :created
    rescue StripePaymentService::PaymentError => e
      render_decline(e)
    end

    # POST /api/:organization/payments/refund
    def refund
      payment = scoped(Payment).find(params[:payment_id])
      refund = stripe_service.refund(payment: payment, amount: params[:amount].presence&.to_d)

      render json: { payment: serialize_payment(refund), message: 'Refund issued' }, status: :created
    rescue StripePaymentService::PaymentError => e
      render_decline(e)
    end

    # POST /api/:organization/payments/methods
    #   { customer_profile_id: 3, stripe_payment_method: "pm_123", card_last4: "4242", card_brand: "visa" }
    # Stores the renter's card on their customer profile (the "Add card" action
    # in /account/billing). Stripe is simulated when no live key is configured,
    # exactly like the deposit lifecycle.
    def methods
      profile = scoped(CustomerProfile).find(params[:customer_profile_id])
      ensure_own_profile!(profile)

      token = params[:stripe_payment_method].presence ||
              params[:payment_method_token].presence ||
              "pm_sim_#{SecureRandom.hex(8)}"

      profile.update!(
        stripe_payment_method_token: token,
        card_last4: params[:card_last4].presence || last4_from(token),
        card_brand: params[:card_brand].presence || 'visa',
        stripe_customer_token: profile.stripe_customer_token.presence ||
                               "cus_sim_#{SecureRandom.hex(8)}"
      )

      render json: {
        message: 'Payment method saved',
        payment_method: {
          id: profile.id,
          customer_profile_id: profile.id,
          stripe_payment_method: profile.stripe_payment_method_token,
          stripe_customer_token: profile.stripe_customer_token,
          card_last4: profile.card_last4,
          card_brand: profile.card_brand
        },
        customer_profile: profile.as_rhino_json.merge(profile.rhino_computed_attributes)
      }, status: :created
    end

    private

    def ensure_own_profile!(profile)
      return unless current_user.role_slug_for_validation(current_organization) == 'customer'
      return if profile.user_id == current_user.id

      render json: { message: 'This action is unauthorized.' }, status: :forbidden
    end

    def last4_from(token)
      digits = token.to_s.gsub(/\D/, '')
      digits.length >= 4 ? digits[-4..] : '4242'
    end

    def stripe_service
      StripePaymentService.new(organization: current_organization)
    end

    def finalize_settlement!(rental, calculator)
      ActiveRecord::Base.transaction do
        rental.recalculate_totals!
        rental.update!(
          actual_return_datetime: rental.actual_return_datetime || Time.current,
          status: 'completed',
          balance_owed_amount: calculator.balance_owed
        )
        rental.vehicle&.update_columns(status: 'cleaning', updated_at: Time.current)
        rental.inspections.kept.where(inspection_type: 'check_in')
              .update_all(status: 'completed', checked_in_at: Time.current)
      end
      NotificationService.new(rental.reload).send_receipt
    end

    def settle_payload(rental, result, calculator = nil)
      calculator ||= RentalSettlementCalculator.new(rental)
      {
        rental: serialize_rental(rental.reload),
        capture: result[:capture] ? serialize_payment(result[:capture]) : nil,
        release: result[:release] ? serialize_payment(result[:release]) : nil,
        settlement: calculator.summary,
        invoice_required: calculator.balance_owed.positive?
      }
    end

    def render_decline(error, extra: {})
      render json: {
        message: error.message,
        code: error.code,
        decline_reason: error.decline_reason,
        errors: { payment: [error.message] }
      }.merge(extra), status: :unprocessable_entity
    end

    def serialize_payment(payment)
      payment.as_rhino_json.merge(payment.rhino_computed_attributes)
    end

    def serialize_rental(rental)
      rental.as_rhino_json.merge(rental.rhino_computed_attributes)
    end
  end
end
