# frozen_string_literal: true

require "test_helper"

# AC-12 / AC-21 / AC-98 / AC-99 / AC-100 — VehicleCategory + seasonal pricing.
class VehicleCategoryTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "category-org")
    @graph = build_rental_graph(organization: @org)
    @category = @graph[:category]
  end

  test "baggage capacity is persisted (AC-12)" do
    assert_equal 3, @category.baggage_capacity
  end

  test "transmission is validated against the supported set (AC-21)" do
    assert_equal "automatic", @category.transmission
    @category.transmission = "cvt"
    assert_not @category.valid?
  end

  test "baggage and passenger capacity must be non-negative integers" do
    @category.passenger_capacity = -1
    assert_not @category.valid?
  end

  test "effective daily rate honours an active seasonal multiplier (AC-98)" do
    assert_equal BigDecimal("100"), @category.effective_daily_rate

    RateRule.create!(
      organization: @org, vehicle_category: @category, name: "Summer peak",
      season_name: "summer_peak", start_date: Date.current - 1.day, end_date: Date.current + 1.day,
      daily_multiplier: 1.35, weekend_multiplier: 1.1, min_rental_days: 1, is_active: true
    )
    assert_equal BigDecimal("135.00"), @category.effective_daily_rate
  end

  test "an inactive rate rule never applies" do
    RateRule.create!(
      organization: @org, vehicle_category: @category, name: "Retired", season_name: "retired",
      start_date: Date.current - 1.day, end_date: Date.current + 1.day,
      daily_multiplier: 2, weekend_multiplier: 1, min_rental_days: 1, is_active: false
    )
    assert_equal BigDecimal("100"), @category.effective_daily_rate
  end

  test "computed attributes expose the catalogue contract (AC-1)" do
    attrs = @category.rhino_computed_attributes
    assert_equal 100.0, attrs["rate"]
    assert_equal 1, attrs["vehicle_count"]
    assert_equal 1, attrs["available_vehicle_count"]
    assert_equal @graph[:vehicle].license_plate, attrs["vehicles"].first["license_plate"]
  end

  test "a category with vehicles cannot be destroyed" do
    assert_not @category.destroy
    assert @category.errors.any?
  end
end
