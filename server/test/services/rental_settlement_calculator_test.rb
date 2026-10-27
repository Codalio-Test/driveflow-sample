# frozen_string_literal: true

require "test_helper"

# AC-91 / AC-92 / AC-93 / AC-104 / AC-127 — the surcharge and late-fee engine.
class RentalSettlementCalculatorTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "settlement-org")
    @graph = build_rental_graph(organization: @org, initial_odometer: 10_000,
                                initial_fuel_percentage: 100,
                                pickup_datetime: 30.days.ago.change(hour: 9),
                                scheduled_return_datetime: 28.days.ago.change(hour: 9))
    @rental = @graph[:rental]
    @rental.update!(vehicle: @graph[:vehicle])
  end

  def return_inspection(fuel:, odometer:)
    Inspection.create!(
      organization: @org, rental: @rental, vehicle: @graph[:vehicle],
      inspection_type: "check_in",
      fuel_percentage: fuel,
      odometer_reading: odometer,
      # Drafts are allowed to omit readings — only a *completed* walkaround
      # requires them, so the calculator can be exercised with partial data.
      status: fuel.nil? ? "in_progress" : "completed"
    )
  end

  # Sets the return benchmarks the calculator reads and returns it wired to a
  # matching check-in inspection.
  def calculator(fuel: 100, odometer: 10_000, returned_at: nil)
    inspection = return_inspection(fuel: fuel, odometer: odometer)
    @rental.update!(final_odometer: odometer,
                    final_fuel_percentage: fuel,
                    actual_return_datetime: returned_at || @rental.actual_return_datetime)
    RentalSettlementCalculator.new(@rental.reload, return_inspection: inspection)
  end

  test "the refueling rate defaults to 8.00 per gallon (AC-99 / AC-104)" do
    assert_equal BigDecimal("8.00"), RateCalculator.refuel_price_per_gallon(@org)
  end

  test "missing fuel volume is derived from tank capacity and the fuel variance (AC-91)" do
    calc = calculator(fuel: 60)
    assert_equal BigDecimal("40.00"), calc.fuel_variance_percentage
    assert_equal BigDecimal("5.60"), calc.missing_fuel_gallons # 14 gal × 40%
    assert_equal BigDecimal("44.80"), calc.refueling_charge_amount
  end

  test "no refueling charge when the tank comes back full" do
    calc = calculator(fuel: 100)
    assert_equal BigDecimal("0"), calc.refueling_charge_amount
  end

  test "refueling never pays the renter back for an overfilled tank" do
    # An electric/overfilled return: the gauge reads higher than at departure.
    inspection = return_inspection(fuel: nil, odometer: 10_000)
    @rental.update!(final_fuel_percentage: 115)
    calc = RentalSettlementCalculator.new(@rental.reload, return_inspection: inspection)
    assert_equal BigDecimal("0"), calc.fuel_variance_percentage
    assert_equal BigDecimal("0"), calc.refueling_charge_amount
  end

  test "excess mileage is billed at the contracted per-mile rate (AC-92)" do
    calc = calculator(odometer: 10_700)
    assert_equal 2 * 200, calc.mileage_allowance
    assert_equal 700, calc.miles_driven
    assert_equal 300, calc.excess_miles
    assert_equal BigDecimal("105.00"), calc.excess_mileage_charge_amount # 300 × 0.35
  end

  test "mileage inside the allowance is free (AC-92)" do
    calc = calculator(odometer: 10_300)
    assert_equal 0, calc.excess_miles
    assert_equal BigDecimal("0"), calc.excess_mileage_charge_amount
  end

  test "a return inside the 60-minute grace pays no late fee (AC-93 / AC-127)" do
    @rental.update!(scheduled_return_datetime: 30.minutes.ago)
    calc = calculator(returned_at: Time.current)
    assert_equal 60, calc.late_grace_minutes
    assert_equal BigDecimal("0"), calc.late_fee_amount
  end

  test "each billable hour past the grace window adds the hourly rate (AC-93)" do
    @rental.update!(scheduled_return_datetime: 2.hours.ago)
    calc = calculator(returned_at: Time.current)
    assert_equal 1.0, calc.billable_overdue_hours
    assert_equal BigDecimal("35.00"), calc.late_fee_amount # 1h × $35
  end

  test "the hourly late fee is capped at one daily rate (AC-127 / AC-104)" do
    @rental.update!(scheduled_return_datetime: 5.hours.ago)
    calc = calculator(returned_at: Time.current)
    assert_equal BigDecimal("100.00"), calc.daily_rate_cap
    assert_equal BigDecimal("100.00"), calc.late_fee_amount
    assert calc.summary["late_fee_capped"]
  end

  test "the summary aggregates every assessed line" do
    @rental.update!(scheduled_return_datetime: 3.hours.ago)
    calc = calculator(fuel: 50, odometer: 10_500, returned_at: Time.current)
    summary = calc.summary
    assert_equal 8.0, summary["refuel_price_per_gallon"]
    assert_equal 7.0, summary["missing_fuel_gallons"]
    assert_equal 50.0, summary["fuel_variance_percentage"]
    assert_equal 60, summary["late_grace_minutes"]
    assert_equal 100.0, summary["daily_cap"]
    assert summary["grand_total"].positive?
    assert_equal 3, summary["formulas"].size
  end

  test "persist! writes the surcharge lines and returns the grand total" do
    @rental.update!(scheduled_return_datetime: 3.hours.ago)
    calc = calculator(fuel: 50, odometer: 10_500, returned_at: Time.current)
    total = calc.persist!

    assert total.positive?
    types = @rental.rental_charges.kept.pluck(:charge_type)
    assert_includes types, "refueling_charge"
    assert_includes types, "excess_mileage"
    assert_includes types, "late_return_fee"
    assert_equal @rental.reload.rental_charges.kept.sum(:amount).round(2), @rental.total_charges_amount
  end

  test "lines are returned for the API serializer" do
    calc = calculator(fuel: 50)
    line = calc.lines.find { |l| l[:charge_type] == "refueling_charge" }
    assert_not_nil line
    assert line.key?(:amount)
  end
end
