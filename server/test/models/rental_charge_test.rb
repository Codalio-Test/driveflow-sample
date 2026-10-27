# frozen_string_literal: true

require "test_helper"

# AC-10 / AC-102 — RentalCharge (quantity + unit price are real columns).
class RentalChargeTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "charge-org")
    @graph = build_rental_graph(organization: @org)
    @charge = RentalCharge.create!(
      organization: @org, rental: @graph[:rental], charge_type: "base_rate",
      description: "Compact SUV 3-day base rental", unit_price: 68.50, quantity: 3, amount: 205.50
    )
  end

  test "quantity is persisted (AC-10)" do
    assert_equal BigDecimal("3"), @charge.quantity
  end

  test "unit price is persisted (AC-102)" do
    assert_equal BigDecimal("68.50"), @charge.unit_price
    assert_equal BigDecimal("205.50"), @charge.amount
  end

  test "charge type vocabulary covers the settlement line items" do
    %w[base_rate insurance_protection equipment_addon excess_mileage
       refueling_charge late_return_fee damage_claim sales_tax].each do |type|
      @charge.charge_type = type
      assert @charge.valid?, "#{type} should be a valid charge type"
    end
    @charge.charge_type = "mystery_fee"
    assert_not @charge.valid?
  end

  test "description and amount are required" do
    blank = RentalCharge.new(organization: @org, rental: @graph[:rental])
    assert_not blank.valid?
    assert_includes blank.errors.attribute_names, :description
    assert_includes blank.errors.attribute_names, :amount
  end

  test "creating a charge refreshes the rental totals" do
    @graph[:rental].recalculate_totals!
    assert_equal BigDecimal("205.50"), @graph[:rental].reload.total_charges_amount
  end

  test "computed attributes expose the label contract" do
    attrs = @charge.rhino_computed_attributes
    assert_equal "Base rate", attrs["category"]
    assert_equal 205.5, attrs["total"]
  end
end
