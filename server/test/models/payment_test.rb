# frozen_string_literal: true

require "test_helper"

# AC-36 / AC-38 / AC-40 / AC-103 — the Payment (Stripe transaction) model.
class PaymentTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "payment-org")
    @graph = build_rental_graph(organization: @org)
  end

  def payment(attrs = {})
    Payment.create!({
      organization: @org, rental: @graph[:rental], customer_profile: @graph[:profile],
      transaction_type: "deposit_hold", amount: 300, status: "succeeded",
      payment_method_last4: "4242", processed_at: Time.current,
      stripe_payment_intent_key: "pi_test_#{SecureRandom.hex(6)}"
    }.merge(attrs))
  end

  test "transaction types cover the whole deposit lifecycle (AC-103)" do
    %w[deposit_hold deposit_capture deposit_release rental_payment overdue_settlement refund].each do |type|
      assert_includes Payment::TRANSACTION_TYPES, type
    end
  end

  test "amount must be positive" do
    assert_not Payment.new(organization: @org, rental: @graph[:rental],
                           transaction_type: "deposit_hold", amount: 0, status: "succeeded").valid?
  end

  test "status vocabulary is normalized" do
    assert_equal %w[succeeded pending failed refunded], Payment::STATUSES
    assert_not Payment.new(organization: @org, rental: @graph[:rental],
                           transaction_type: "deposit_hold", amount: 10, status: "maybe").valid?
  end

  test "a hold marks the rental deposit as secured (AC-36)" do
    payment
    assert_equal "Held", @graph[:rental].reload.deposit_status
  end

  test "total paid amount excludes holds and releases (AC-40)" do
    payment
    payment(transaction_type: "deposit_release", amount: 300)
    payment(transaction_type: "rental_payment", amount: 596.40)
    @graph[:rental].recalculate_totals!
    assert_equal BigDecimal("596.40"), @graph[:rental].reload.total_paid_amount
  end

  test "computed attributes drive the transaction audit table (AC-77)" do
    record = payment
    attrs = record.rhino_computed_attributes
    assert_equal @graph[:rental].reservation_number, attrs["rental"]
    assert_equal "Deposit hold", attrs["type"]
    assert_equal "debit", attrs["direction"]
    assert_equal "$300.00", attrs["amount_display"]
  end

  test "customers only see payments attached to their own profile (AC-114)" do
    customer_role = create_role(slug: "customer")
    customer = create_user(email: "payment-customer@example.com")
    UserRole.create!(user: customer, organization: @org, role: customer_role)
    @graph[:profile].update!(user: customer)
    mine = payment
    other_profile = CustomerProfile.create!(organization: @org, full_name: "Other",
                                            email: "other-#{SecureRandom.hex(3)}@example.com")
    theirs = payment(customer_profile: other_profile)

    visible = with_context(user: customer, organization: @org) { Payment.pluck(:id) }
    assert_includes visible, mine.id
    assert_not_includes visible, theirs.id
  end
end
