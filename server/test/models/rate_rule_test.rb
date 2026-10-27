# frozen_string_literal: true

require "test_helper"

# AC-27 / AC-34 / AC-97 / AC-99 / AC-100 / AC-101 — RateRule pricing rules.
class RateRuleTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "rate-org")
    @graph = build_rental_graph(organization: @org)
    @rule = RateRule.create!(
      organization: @org, vehicle_category: @graph[:category], name: "Standard Year-Round",
      season_name: "regular", start_date: Date.current - 1.day, end_date: Date.current + 30,
      daily_multiplier: 1.0, weekend_multiplier: 1.15, min_rental_days: 1, is_active: true
    )
  end

  test "min rental days defaults to 1 and is required (AC-27)" do
    assert_equal 1, @rule.min_rental_days
    @rule.min_rental_days = nil
    assert_not @rule.valid?
  end

  test "season name is persisted (AC-34)" do
    assert_equal "regular", @rule.season_name
  end

  test "the premium refueling rate is configurable (AC-99)" do
    refuel = RateRule.create!(
      organization: @org, vehicle_category: @graph[:category], name: "Premium Refueling",
      season_name: "refueling_rate", daily_multiplier: 8.0, weekend_multiplier: 1.0,
      min_rental_days: 1, is_active: true
    )
    assert_equal BigDecimal("8.00"), RateCalculator.refuel_price_per_gallon(@org)
    assert_equal "$8.00/gal", refuel.display_value
  end

  test "negative multipliers are rejected (AC-97 / AC-100)" do
    @rule.daily_multiplier = -1
    assert_not @rule.valid?
    assert_includes @rule.errors.attribute_names, :daily_multiplier
  end

  test "an end date before the start date is rejected (AC-97 / AC-100)" do
    @rule.end_date = @rule.start_date - 1.day
    assert_not @rule.valid?
    assert_includes @rule.errors[:end_date], "must be on or after the start date"
  end

  test "display contract drives the /admin/rates table (AC-97)" do
    attrs = @rule.rhino_computed_attributes
    assert_equal "$100.00/day", attrs["value"]
    assert_equal "Base", attrs["priority"]
    assert attrs["scope"].include?(@graph[:category].name)
  end

  test "customers only ever see active rules" do
    customer_role = create_role(slug: "customer")
    customer = create_user(email: "rate-customer@example.com")
    UserRole.create!(user: customer, organization: @org, role: customer_role)
    retired = RateRule.create!(organization: @org, vehicle_category: @graph[:category],
                               name: "Retired", daily_multiplier: 1.0, weekend_multiplier: 1.0,
                               min_rental_days: 1, is_active: false)

    visible = with_context(user: customer, organization: @org) { RateRule.pluck(:id) }
    assert_includes visible, @rule.id
    assert_not_includes visible, retired.id
  end
end
