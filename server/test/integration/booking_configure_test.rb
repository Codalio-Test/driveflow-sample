# frozen_string_literal: true

require "test_helper"

# AC-2 / AC-122 — protection tier and add-on selections persist on the
# reservation as RentalCharge rows during /booking/configure.
class BookingConfigureTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization(slug: "configure-org")
    @graph = build_rental_graph(organization: @org)
  end

  def json_headers
    { "Content-Type" => "application/json" }
  end

  test "tier options and add-on options are exposed by the service (AC-2)" do
    tiers = BookingChargeService.tier_options.map { |t| t[:name] }
    addons = BookingChargeService.addon_options.map { |a| a[:key] }
    assert_equal %w[Basic Standard Full], tiers
    assert_includes addons, "child_seat"
    assert_includes addons, "additional_driver"
    assert_includes addons, "roadside_assistance"
  end

  test "persisting a standard tier writes an insurance_protection line (AC-122)" do
    @graph[:rental].update!(protection_tier: "standard")
    BookingChargeService.new(@graph[:rental]).persist!

    line = @graph[:rental].rental_charges.kept.find_by(charge_type: "insurance_protection")
    assert_not_nil line
    assert_equal BigDecimal("12"), line.unit_price
    assert_equal BigDecimal("2"), line.quantity
    assert_equal BigDecimal("24"), line.amount
  end

  test "the basic tier adds no protection line" do
    @graph[:rental].update!(protection_tier: "basic")
    BookingChargeService.new(@graph[:rental]).persist!
    assert_nil @graph[:rental].rental_charges.kept.find_by(charge_type: "insurance_protection")
  end

  test "add-ons persist as equipment_addon lines and survive re-persisting (AC-122)" do
    @graph[:rental].update!(protection_tier: "full")
    BookingChargeService.new(@graph[:rental]).persist!

    # The renter adds a child seat, then the tier is re-persisted.
    @graph[:rental].rental_charges.create!(
      organization: @org, rental: @graph[:rental], charge_type: "equipment_addon",
      description: "Child safety seat", unit_price: 8, quantity: 2, amount: 16
    )
    BookingChargeService.new(@graph[:rental].reload).persist!

    addons = @graph[:rental].rental_charges.kept.where(charge_type: "equipment_addon")
    assert_equal 1, addons.count
    assert_equal BigDecimal("16"), addons.first.amount
  end

  test "re-persisting replaces stale rate lines instead of duplicating them (AC-122)" do
    @graph[:rental].update!(protection_tier: "standard")
    BookingChargeService.new(@graph[:rental]).persist!
    first = @graph[:rental].rental_charges.kept.where(charge_type: "base_rate").count

    BookingChargeService.new(@graph[:rental].reload).persist!
    assert_equal first, @graph[:rental].rental_charges.kept.where(charge_type: "base_rate").count
  end

  test "the reservation total reflects tier plus add-ons plus tax (AC-2)" do
    @graph[:rental].update!(protection_tier: "full")
    total = BookingChargeService.new(@graph[:rental]).persist!
    assert total.positive?
    tax = @graph[:rental].rental_charges.kept.find_by(charge_type: "sales_tax")
    assert_not_nil tax
    assert_equal total, @graph[:rental].reload.total_charges_amount
  end

  test "surcharge lines produced at return time are preserved (AC-91 / AC-122)" do
    BookingChargeService.new(@graph[:rental]).persist!
    @graph[:rental].rental_charges.create!(
      organization: @org, rental: @graph[:rental], charge_type: "refueling_charge",
      description: "fuel", unit_price: 8, quantity: 3, amount: 24
    )
    BookingChargeService.new(@graph[:rental].reload).persist!
    assert @graph[:rental].rental_charges.kept.exists?(charge_type: "refueling_charge")
  end
end
