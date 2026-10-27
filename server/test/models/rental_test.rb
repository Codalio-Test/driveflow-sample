# frozen_string_literal: true

require "test_helper"

# AC-4 / AC-90 / AC-95 / AC-96 / AC-125 / AC-127 — the Rental data model.
class RentalTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "rental-org")
    @graph = build_rental_graph(organization: @org)
    @rental = @graph[:rental]
  end

  test "postal code of the branch is persisted (AC-5)" do
    assert_equal "94105", @graph[:location].postal_code
  end

  test "status vocabulary is the normalized enum (AC-125)" do
    assert_equal %w[reserved confirmed active overdue completed cancelled], Rental::STATUSES
    Rental::STATUSES.each do |status|
      @rental.status = status
      assert @rental.valid?, "status #{status} should be valid"
    end
    @rental.status = "on_rent"
    assert_not @rental.valid?
  end

  test "return must be after pickup (AC-4 inline validation)" do
    @rental.scheduled_return_datetime = @rental.pickup_datetime - 1.day
    assert_not @rental.valid?
    assert_includes @rental.errors[:scheduled_return_datetime], "must be after the pickup time"
  end

  test "reservation number is generated when absent" do
    rental = Rental.new(
      organization: @org, customer_profile: @graph[:profile], vehicle_category: @graph[:category],
      pickup_datetime: Time.current, scheduled_return_datetime: 1.day.from_now,
      scheduled_duration_days: 1, status: "reserved"
    )
    rental.valid?
    assert_match(/\ADF-\d{4}-\d{4}\z/, rental.reservation_number)
  end

  test "actual return datetime and dropoff location code are persisted (AC-95 / AC-96)" do
    @rental.update!(actual_return_datetime: Time.current, dropoff_location_code: "LAX-01")
    @rental.reload
    assert_not_nil @rental.actual_return_datetime
    assert_equal "LAX-01", @rental.dropoff_location_code
  end

  test "60-minute grace period is authoritative (AC-127)" do
    assert_equal 60, Rental::LATE_GRACE_MINUTES
    @rental.scheduled_return_datetime = 2.hours.ago
    assert_in_delta (@rental.scheduled_return_datetime + 60.minutes).to_i, @rental.grace_expires_at.to_i, 2
  end

  test "no late fee inside the grace window" do
    @rental.scheduled_return_datetime = 45.minutes.ago
    @rental.actual_return_datetime = Time.current
    assert_not @rental.beyond_grace?
    assert_equal 0, @rental.billable_overdue_hours
    assert_equal BigDecimal("0"), @rental.late_fee_accrued
  end

  test "hourly late fee accrues past the grace window" do
    @rental.scheduled_return_datetime = 2.hours.ago
    @rental.actual_return_datetime = Time.current
    assert @rental.beyond_grace?
    assert_equal 1.0, @rental.billable_overdue_hours
    assert_equal BigDecimal("35.00"), @rental.late_fee_accrued # 1h × $35
    assert_not @rental.late_fee_capped?
  end

  test "late fee is capped at one full daily rate (AC-127)" do
    @rental.pickup_datetime = 20.days.ago.change(hour: 9)
    @rental.scheduled_return_datetime = 18.days.ago.change(hour: 9)
    @rental.actual_return_datetime = Time.current
    assert @rental.late_fee_capped?
    assert_equal @rental.daily_rate_cap, @rental.late_fee_accrued
    assert_equal BigDecimal("100.00"), @rental.late_fee_accrued
  end

  test "total paid amount is persisted and balance recalculates (AC-40)" do
    RentalCharge.create!(organization: @org, rental: @rental, charge_type: "base_rate",
                         description: "base", unit_price: 100, quantity: 2, amount: 200)
    Payment.create!(organization: @org, rental: @rental, transaction_type: "rental_payment",
                    amount: 120, status: "succeeded", processed_at: Time.current)
    @rental.recalculate_totals!
    @rental.reload
    assert_equal BigDecimal("200"), @rental.total_charges_amount
    assert_equal BigDecimal("120"), @rental.total_paid_amount
    assert_equal BigDecimal("80"), @rental.balance_owed_amount
  end

  test "deposit status badge values are derived from payments (AC-36)" do
    assert_equal "Unsecured", @rental.deposit_status

    Payment.create!(organization: @org, rental: @rental, transaction_type: "deposit_hold",
                    amount: 300, status: "succeeded", processed_at: Time.current)
    assert_equal "Held", @rental.reload.deposit_status

    Payment.create!(organization: @org, rental: @rental, transaction_type: "deposit_capture",
                    amount: 100, status: "succeeded", processed_at: Time.current)
    Payment.create!(organization: @org, rental: @rental, transaction_type: "deposit_release",
                    amount: 200, status: "succeeded", processed_at: Time.current)
    assert_equal "Partially Refunded", @rental.reload.deposit_status
  end

  test "protection tier and add-ons persist as charges (AC-122)" do
    @rental.update!(protection_tier: "full")
    BookingChargeService.new(@rental).persist!
    types = @rental.rental_charges.kept.pluck(:charge_type)
    assert_includes types, "insurance_protection"
    assert_equal "full", @rental.reload.protection_tier
  end

  test "computed attributes expose the queue and voucher contract (AC-15)" do
    attrs = @rental.rhino_computed_attributes
    assert_equal @graph[:profile].full_name, attrs["customer"]
    assert_match(/Toyota RAV4/, attrs["vehicle"])
    assert attrs["qr_code_url"].start_with?("data:image")
    assert_equal @rental.reservation_number, attrs["reference"]
    assert attrs["due"].present? && attrs["balance"].present?
  end

  test "tenant scoping isolates rentals per organization" do
    other = create_organization(slug: "rental-other-org")
    other_graph = build_rental_graph(organization: other)
    in_org = Rental.unscoped.for_organization(@org).pluck(:id)
    assert_includes in_org, @rental.id
    assert_not_includes in_org, other_graph[:rental].id
  end
end
