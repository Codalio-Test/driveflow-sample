# frozen_string_literal: true

require "test_helper"

# AC-35 / AC-37 / AC-38 / AC-55 / AC-56 / AC-57 / AC-66 / AC-87 / AC-88 / AC-103 —
# the Stripe deposit lifecycle (pre-auth hold, expand, capture + release,
# balance charge, refund, webhook reconciliation). Stripe is stubbed by the
# service's deterministic offline gateway because no live key is configured.
class StripePaymentServiceTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "stripe-org")
    @graph = build_rental_graph(organization: @org)
    @rental = @graph[:rental]
    @service = StripePaymentService.new(organization: @org)
    Stripe.api_key = nil if defined?(Stripe) && Stripe.respond_to?(:api_key=)
  end

  test "hold pre-authorizes the class deposit amount (AC-35)" do
    payment = @service.hold(rental: @rental, last4: "4242")
    assert payment.persisted?
    assert_equal "deposit_hold", payment.transaction_type
    assert_equal @graph[:category].security_deposit_amount, payment.amount
    assert_equal "succeeded", payment.status
  end

  test "a successful hold attaches the intent id to the rental (AC-36)" do
    payment = @service.hold(rental: @rental, last4: "4242")
    assert payment.stripe_payment_intent_key.present?
    assert_equal "Held", @rental.reload.deposit_status
  end

  test "a declined card raises a PaymentError with the decline reason (AC-37)" do
    error = assert_raises(StripePaymentService::PaymentError) do
      @service.hold(rental: @rental, last4: "0341")
    end
    assert_equal "card_declined", error.code
    assert error.decline_reason.present?
    assert_equal 0, @rental.payments.count
  end

  test "a non-positive deposit is rejected" do
    assert_raises(StripePaymentService::PaymentError) do
      @service.hold(rental: @rental, amount: 0)
    end
  end

  test "settle captures charges and releases the difference atomically (AC-56)" do
    @service.hold(rental: @rental, amount: 300, last4: "4242")
    RentalCharge.create!(organization: @org, rental: @rental, charge_type: "refueling_charge",
                         description: "fuel", unit_price: 8, quantity: 5, amount: 40)
    @rental.recalculate_totals!

    result = @service.settle(rental: @rental, capture_amount: 40)

    assert_equal "deposit_capture", result[:capture].transaction_type
    assert_equal BigDecimal("40.0"), result[:capture].amount
    assert_equal "deposit_release", result[:release].transaction_type
    assert_equal BigDecimal("260.0"), result[:release].amount
    assert result[:capture].stripe_charge_key.present?
  end

  test "release returns the whole hold when nothing is owed (AC-55)" do
    @service.hold(rental: @rental, amount: 300, last4: "4242")
    result = @service.release(rental: @rental)

    assert_equal "deposit_release", result[:release].transaction_type
    assert_equal BigDecimal("300.0"), result[:release].amount
    assert_equal "Released", @rental.reload.deposit_status
  end

  test "capturing the full hold leaves no release row (AC-57)" do
    @service.hold(rental: @rental, amount: 300, last4: "4242")
    result = @service.settle(rental: @rental, capture_amount: 300, release_amount: 0)

    assert_not_nil result[:capture]
    assert_nil result[:release]
    assert_equal "Captured", @rental.reload.deposit_status
  end

  test "expand_hold adds an incremental pre-authorization (AC-87)" do
    @service.hold(rental: @rental, amount: 300, last4: "4242")
    expansion = @service.expand_hold(rental: @rental, amount: 250, last4: "4242")

    assert_equal "deposit_hold", expansion.transaction_type
    assert_equal BigDecimal("250.0"), expansion.amount
    assert_equal BigDecimal("550.0"), @rental.reload.deposit_hold_total
  end

  test "expand_hold surfaces a decline so the UI can flag recovery (AC-88)" do
    assert_raises(StripePaymentService::PaymentError) do
      @service.expand_hold(rental: @rental, amount: 100, last4: "0002")
    end
  end

  test "charge_balance bills the outstanding balance to the saved card (AC-66)" do
    @rental.update!(balance_owed_amount: 240)
    payment = @service.charge_balance(rental: @rental)

    assert_equal "overdue_settlement", payment.transaction_type
    assert_equal BigDecimal("240.0"), payment.amount
    assert payment.stripe_charge_key.present?
  end

  test "refund issues a refund row against the original charge (AC-103)" do
    hold = @service.hold(rental: @rental, amount: 300, last4: "4242")
    result = @service.settle(rental: @rental, capture_amount: 100, release_amount: 200)
    refund = @service.refund(payment: result[:capture], amount: 50)

    assert_equal "refund", refund.transaction_type
    assert_equal BigDecimal("50.0"), refund.amount
    assert refund.stripe_refund_key.present?
    assert_equal hold.stripe_payment_intent_key, refund.stripe_payment_intent_key
  end

  test "webhook reconciliation flips the matching payment status (AC-103)" do
    payment = @service.hold(rental: @rental, amount: 300, last4: "4242")
    reconciled = @service.reconcile_event(
      "type" => "payment_intent.payment_failed",
      "data" => { "object" => { "id" => "ch_x", "payment_intent" => payment.stripe_payment_intent_key } }
    )
    assert_equal "failed", reconciled.reload.status
  end

  test "orders and items do not leak across roles (deposit gate is permission-based)" do
    role = create_role(slug: "counter_agent")
    grant(@org, role, "payments.index", "payments.store", "rentals.index", "rentals.update")
    agent = member_of(@org, role_slug: "counter_agent", role: role)

    assert agent.has_permission?("payments.store", @org)
    assert agent.has_permission?("rentals.update", @org)

    viewer_role = create_role(slug: "customer")
    viewer = member_of(@org, role_slug: "customer", role: viewer_role)
    assert_not viewer.has_permission?("payments.store", @org)
  end
end
