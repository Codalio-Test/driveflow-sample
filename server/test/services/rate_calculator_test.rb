# frozen_string_literal: true

require "test_helper"

# AC-98 / AC-99 / AC-103 / AC-108 — pricing resolution + Stripe deposit lifecycle.
class RateCalculatorTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "rates-org")
    @graph = build_rental_graph(organization: @org)
    @category = @graph[:category]
  end

  test "base rate applies when no seasonal rule matches" do
    assert_equal BigDecimal("100.00"), RateCalculator.new(@category).daily_rate
  end

  test "a seasonal rule inside its window multiplies the base rate (AC-98)" do
    RateRule.create!(organization: @org, vehicle_category: @category, name: "Summer",
                     season_name: "summer_peak", start_date: Date.current - 1.day,
                     end_date: Date.current + 1.day, daily_multiplier: 1.35,
                     weekend_multiplier: 1.25, min_rental_days: 1, is_active: true)
    assert_equal BigDecimal("135.00"), RateCalculator.new(@category).daily_rate
  end

  test "a rule outside its window is ignored (AC-98)" do
    RateRule.create!(organization: @org, vehicle_category: @category, name: "Winter",
                     season_name: "winter", start_date: Date.current + 10,
                     end_date: Date.current + 20, daily_multiplier: 2,
                     weekend_multiplier: 1, min_rental_days: 1, is_active: true)
    assert_equal BigDecimal("100.00"), RateCalculator.new(@category).daily_rate
  end

  test "the refueling rate falls back to the documented 8.00 default (AC-99)" do
    assert_equal BigDecimal("8.00"), RateCalculator.refuel_price_per_gallon(@org)
    assert_equal BigDecimal("8.00"), RateCalculator.refuel_price_per_gallon(nil)
  end

  test "an organization fee schedule overrides the defaults (AC-99)" do
    RateRule.create!(organization: @org, vehicle_category: @category, name: "Refuel",
                     season_name: "refueling_rate", daily_multiplier: 9.25,
                     weekend_multiplier: 1, min_rental_days: 1, is_active: true)
    RateRule.create!(organization: @org, vehicle_category: @category, name: "Late",
                     season_name: "late_return_fee", daily_multiplier: 42,
                     weekend_multiplier: 1, min_rental_days: 1, is_active: true)
    assert_equal BigDecimal("9.25"), RateCalculator.refuel_price_per_gallon(@org)
    assert_equal BigDecimal("42.00"), RateCalculator.late_hourly_fee(@org)
  end
end
