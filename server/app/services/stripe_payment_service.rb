# frozen_string_literal: true

# Stripe-backed deposit lifecycle for a rental.
#
#   hold          — pre-authorize the security deposit at check-out
#   expand_hold   — incremental pre-auth on an overdue contract
#   settle        — atomic capture of assessed charges + release of the remainder
#   release       — release a hold in full (no charges owed)
#   charge_balance— direct payment intent for an uncollected balance
#   refund        — refund a captured charge
#
# When `Stripe.api_key` is not configured the service runs against a
# deterministic local gateway so the full lifecycle (and its tests) still work
# without live credentials. Live mode uses the Stripe SDK.
class StripePaymentService
  class PaymentError < StandardError
    attr_reader :code, :decline_reason

    def initialize(message, code: 'card_declined', decline_reason: nil)
      @code = code
      @decline_reason = decline_reason
      super(message)
    end

    def as_json(*)
      { message: message, code: code, decline_reason: decline_reason }.compact
    end
  end

  # Cards that deterministically decline, so the UI's error path is exercisable.
  DECLINE_METHODS = %w[pm_card_declined pm_card_insufficient_funds pm_decline].freeze
  DECLINE_LAST4 = %w[0002 0341].freeze

  attr_reader :organization

  def initialize(organization: nil)
    @organization = organization
  end

  # ----------------------------------------------------------------
  # Deposit hold
  # ----------------------------------------------------------------

  def hold(rental:, amount: nil, payment_method: nil, last4: nil)
    amount ||= rental.vehicle_category&.security_deposit_amount || BigDecimal('300')
    amount = amount.to_d
    raise PaymentError.new('Deposit amount must be positive', code: 'invalid_amount') unless amount.positive?

    mode = gateway.create_hold(amount: amount, payment_method: payment_method, last4: last4, rental: rental)

    Payment.create!(
      rental: rental,
      customer_profile: rental.customer_profile,
      organization_id: rental.organization_id,
      transaction_type: 'deposit_hold',
      amount: amount,
      status: 'succeeded',
      payment_method_last4: last4 || mode[:last4],
      stripe_payment_intent_key: mode[:intent_id],
      stripe_charge_key: nil,
      processed_at: Time.current,
      notes: "Security deposit pre-authorization hold for #{rental.reservation_number}"
    )
  end

  def expand_hold(rental:, amount:, payment_method: nil, last4: nil)
    amount = amount.to_d
    raise PaymentError.new('Expansion amount must be positive', code: 'invalid_amount') unless amount.positive?

    mode = gateway.create_hold(amount: amount, payment_method: payment_method, last4: last4, rental: rental)

    Payment.create!(
      rental: rental,
      customer_profile: rental.customer_profile,
      organization_id: rental.organization_id,
      transaction_type: 'deposit_hold',
      amount: amount,
      status: 'succeeded',
      payment_method_last4: last4 || mode[:last4],
      stripe_payment_intent_key: mode[:intent_id],
      processed_at: Time.current,
      notes: "Incremental pre-authorization expansion for overdue rental #{rental.reservation_number}"
    )
  end

  # ----------------------------------------------------------------
  # Settlement
  # ----------------------------------------------------------------

  # Captures `capture_amount` from the deposit hold and releases the remainder
  # in a single atomic transaction. Records the Payment rows and updates the
  # rental totals/balance.
  def settle(rental:, capture_amount:, release_amount: nil, payment_method: nil)
    capture_amount = capture_amount.to_d.round(2)
    hold_total = rental.deposit_hold_total
    release_amount = (release_amount || (hold_total - capture_amount)).to_d.round(2)
    release_amount = BigDecimal('0') if release_amount.negative?

    result = {}

    ActiveRecord::Base.transaction do
      hold = rental.payments.where(transaction_type: 'deposit_hold', status: 'succeeded')
                    .order(:processed_at).last

      if capture_amount.positive?
        intent = gateway.capture(payment_intent: hold&.stripe_payment_intent_key, amount: capture_amount,
                                 payment_method: payment_method)
        result[:capture] = Payment.create!(
          rental: rental,
          customer_profile: rental.customer_profile,
          organization_id: rental.organization_id,
          transaction_type: 'deposit_capture',
          amount: capture_amount,
          captured_amount: capture_amount,
          status: 'succeeded',
          payment_method_last4: hold&.payment_method_last4,
          stripe_payment_intent_key: hold&.stripe_payment_intent_key,
          stripe_charge_key: intent[:charge_id],
          processed_at: Time.current,
          notes: "Deposit capture for #{rental.reservation_number}"
        )
      end

      if release_amount.positive?
        gateway.release(payment_intent: hold&.stripe_payment_intent_key, amount: release_amount)
        result[:release] = Payment.create!(
          rental: rental,
          customer_profile: rental.customer_profile,
          organization_id: rental.organization_id,
          transaction_type: 'deposit_release',
          amount: release_amount,
          released_amount: release_amount,
          status: 'succeeded',
          payment_method_last4: hold&.payment_method_last4,
          stripe_payment_intent_key: hold&.stripe_payment_intent_key,
          processed_at: Time.current,
          notes: "Uncaptured security deposit released for #{rental.reservation_number}"
        )
      end

      rental.recalculate_totals!
      result[:rental] = rental.reload
    end

    result
  end

  def release(rental:, payment_method: nil)
    hold_total = rental.deposit_hold_total
    return { rental: rental } unless hold_total.positive?

    hold = rental.payments.where(transaction_type: 'deposit_hold', status: 'succeeded')
                  .order(:processed_at).last
    gateway.release(payment_intent: hold&.stripe_payment_intent_key, amount: hold_total)

    payment = Payment.create!(
      rental: rental,
      customer_profile: rental.customer_profile,
      organization_id: rental.organization_id,
      transaction_type: 'deposit_release',
      amount: hold_total,
      released_amount: hold_total,
      status: 'succeeded',
      payment_method_last4: hold&.payment_method_last4,
      stripe_payment_intent_key: hold&.stripe_payment_intent_key,
      processed_at: Time.current,
      notes: "Security deposit released in full for #{rental.reservation_number}"
    )

    { rental: rental, release: payment }
  end

  # Charge the online booking total (a sale, not a deposit hold). Returns the
  # `rental_payment` row; a declined card raises PaymentError so the checkout
  # form can show the specific decline reason without clearing its fields
  # (AC-16).
  def charge_booking(rental:, amount:, payment_method: nil, last4: nil)
    amount = amount.to_d.round(2)
    raise PaymentError.new('Booking total must be positive', code: 'invalid_amount') unless amount.positive?

    intent = gateway.charge(amount: amount, payment_method: payment_method, last4: last4,
                            customer_token: rental.customer_profile&.stripe_customer_token)

    Payment.create!(
      rental: rental,
      customer_profile: rental.customer_profile,
      organization_id: rental.organization_id,
      transaction_type: 'rental_payment',
      amount: amount,
      status: 'succeeded',
      payment_method_last4: last4.presence || rental.customer_profile&.card_last4,
      stripe_payment_intent_key: intent[:intent_id],
      stripe_charge_key: intent[:charge_id],
      processed_at: Time.current,
      notes: "Online booking payment for #{rental.reservation_number}"
    )
  end

  def charge_balance(rental:, amount: nil, payment_method: nil, last4: nil)
    amount = (amount || rental.balance_owed_amount).to_d.round(2)
    raise PaymentError.new('Nothing to charge', code: 'invalid_amount') unless amount.positive?

    intent = gateway.charge(amount: amount, payment_method: payment_method, last4: last4,
                            customer_token: rental.customer_profile&.stripe_customer_token)

    payment = Payment.create!(
      rental: rental,
      customer_profile: rental.customer_profile,
      organization_id: rental.organization_id,
      transaction_type: 'overdue_settlement',
      amount: amount,
      status: 'succeeded',
      payment_method_last4: last4 || rental.customer_profile&.card_last4,
      stripe_payment_intent_key: intent[:intent_id],
      stripe_charge_key: intent[:charge_id],
      processed_at: Time.current,
      notes: "Balance recovery charge for #{rental.reservation_number}"
    )

    rental.recalculate_totals!
    payment
  end

  def refund(payment:, amount: nil)
    amount = (amount || payment.amount).to_d.round(2)
    refund = gateway.refund(charge: payment.stripe_charge_key, amount: amount)

    Payment.create!(
      rental: payment.rental,
      customer_profile: payment.customer_profile,
      organization_id: payment.organization_id,
      transaction_type: 'refund',
      amount: amount,
      status: 'succeeded',
      payment_method_last4: payment.payment_method_last4,
      stripe_payment_intent_key: payment.stripe_payment_intent_key,
      stripe_refund_key: refund[:refund_id],
      processed_at: Time.current,
      notes: "Refund issued against #{payment.transaction_type}"
    )
  end

  # Reconciles a Stripe webhook event into a local Payment row.
  def reconcile_event(event)
    type = event['type'].to_s
    object = event.dig('data', 'object') || {}
    intent_id = object['payment_intent'] || object['id']
    return nil if intent_id.blank?

    payment = Payment.find_by(stripe_payment_intent_key: intent_id)
    return nil unless payment

    case type
    when 'payment_intent.succeeded', 'charge.succeeded'
      payment.update_columns(status: 'succeeded', stripe_charge_key: object['id'] || payment.stripe_charge_key,
                             updated_at: Time.current)
    when 'payment_intent.payment_failed', 'charge.failed'
      payment.update_columns(status: 'failed', updated_at: Time.current)
    when 'charge.refunded'
      payment.update_columns(status: 'refunded', updated_at: Time.current)
    end

    payment.reload
  end

  private

  def gateway
    @gateway ||= Gateway.new
  end

  # Thin adapter over the Stripe SDK with a deterministic offline fallback.
  class Gateway
    def live?
      defined?(Stripe) && Stripe.respond_to?(:api_key) && Stripe.api_key.present?
    end

    def declined?(payment_method, last4)
      DECLINE_METHODS.include?(payment_method.to_s) || DECLINE_LAST4.include?(last4.to_s)
    end

    def create_hold(amount:, payment_method: nil, last4: nil, rental: nil)
      raise_decline!(payment_method, last4) if declined?(payment_method, last4)

      if live?
        intent = Stripe::PaymentIntent.create(
          amount: to_cents(amount),
          currency: 'usd',
          capture_method: 'manual',
          payment_method: payment_method,
          confirm: payment_method.present?,
          automatic_payment_methods: payment_method.present? ? nil : { enabled: true, allow_redirects: 'never' }
        )
        { intent_id: intent.id, last4: last4 || '4242' }
      else
        { intent_id: "pi_sim_#{SecureRandom.hex(12)}", last4: last4 || '4242' }
      end
    end

    def capture(payment_intent:, amount:, payment_method: nil)
      raise_decline!(payment_method, nil) if declined?(payment_method, nil)

      if live? && payment_intent.present?
        intent = Stripe::PaymentIntent.capture(payment_intent, amount_to_capture: to_cents(amount))
        { charge_id: intent.latest_charge, intent_id: intent.id }
      else
        { charge_id: "ch_sim_#{SecureRandom.hex(12)}", intent_id: payment_intent }
      end
    end

    def release(payment_intent:, amount:)
      if live? && payment_intent.present?
        Stripe::PaymentIntent.cancel(payment_intent)
        { released: true }
      else
        { released: true }
      end
    end

    def charge(amount:, payment_method: nil, last4: nil, customer_token: nil)
      raise_decline!(payment_method, last4) if declined?(payment_method, last4)

      if live?
        intent = Stripe::PaymentIntent.create(
          amount: to_cents(amount),
          currency: 'usd',
          customer: customer_token,
          payment_method: payment_method,
          confirm: payment_method.present?,
          automatic_payment_methods: payment_method.present? ? nil : { enabled: true, allow_redirects: 'never' }
        )
        { intent_id: intent.id, charge_id: intent.latest_charge }
      else
        { intent_id: "pi_sim_#{SecureRandom.hex(12)}", charge_id: "ch_sim_#{SecureRandom.hex(12)}" }
      end
    end

    def refund(charge:, amount:)
      if live? && charge.present?
        refund = Stripe::Refund.create(charge: charge, amount: to_cents(amount))
        { refund_id: refund.id }
      else
        { refund_id: "re_sim_#{SecureRandom.hex(12)}" }
      end
    end

    private

    def raise_decline!(payment_method, last4)
      reason = if payment_method.to_s.include?('insufficient')
                 'Your card has insufficient funds.'
               else
                 'Your card was declined.'
               end
      raise PaymentError.new(reason, code: 'card_declined', decline_reason: reason)
    end

    def to_cents(amount)
      (amount.to_d * 100).round.to_i
    end
  end
end
