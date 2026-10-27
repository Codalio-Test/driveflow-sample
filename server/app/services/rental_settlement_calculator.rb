# frozen_string_literal: true

# Computes the return-time surcharge lines for a rental:
#
#   * Refueling  — missing gallons = tank capacity × fuel % variance,
#                  billed at the premium per-gallon rate (default $8.00/gal).
#   * Excess mileage — miles beyond the contracted allowance × per-mile rate.
#   * Late return — hourly fee past the 60-minute grace period, capped at
#                  one full daily rate.
#
# All monetary math is done in BigDecimal so the numbers are exact and
# reproducible in tests.
class RentalSettlementCalculator
  DEFAULT_TANK_CAPACITY_GALLONS = BigDecimal('14.00')

  attr_reader :rental, :return_inspection

  def initialize(rental, return_inspection: nil)
    @rental = rental
    @return_inspection = return_inspection || rental.inspections.kept.find_by(inspection_type: 'check_in')
  end

  # ----------------------------------------------------------------
  # Refueling
  # ----------------------------------------------------------------

  def tank_capacity_gallons
    rental.vehicle&.fuel_tank_capacity_gallons&.to_d || DEFAULT_TANK_CAPACITY_GALLONS
  end

  def fuel_variance_percentage
    departure = departure_fuel
    arrival = return_fuel
    return BigDecimal('0') if departure.nil? || arrival.nil?

    [departure - arrival, 0].max.to_d
  end

  def missing_fuel_gallons
    (tank_capacity_gallons * (fuel_variance_percentage / 100)).round(2)
  end

  def refuel_price_per_gallon
    RateCalculator.refuel_price_per_gallon(rental.organization)
  end

  def departure_fuel
    rental.initial_fuel_percentage ||
      rental.inspections.kept.find_by(inspection_type: 'check_out')&.fuel_percentage
  end

  def return_fuel
    return_inspection&.fuel_percentage || rental.final_fuel_percentage
  end

  def refueling_charge_amount
    (missing_fuel_gallons * refuel_price_per_gallon).round(2)
  end

  # ----------------------------------------------------------------
  # Excess mileage
  # ----------------------------------------------------------------

  def mileage_allowance
    per_day = rental.vehicle_category&.mileage_allowance_per_day.to_i
    days = rental.scheduled_duration_days.to_i
    days = 1 if days <= 0
    per_day * days
  end

  def miles_driven
    return 0 if rental.initial_odometer.nil? || rental.final_odometer.nil?

    [rental.final_odometer.to_i - rental.initial_odometer.to_i, 0].max
  end

  def excess_miles
    [miles_driven - mileage_allowance, 0].max
  end

  def excess_mileage_rate
    rental.vehicle_category&.excess_mileage_rate.to_d || BigDecimal('0')
  end

  def excess_mileage_charge_amount
    (excess_miles * excess_mileage_rate).round(2)
  end

  # ----------------------------------------------------------------
  # Late return (60-minute grace, hourly fee capped at the daily rate)
  # ----------------------------------------------------------------

  def late_grace_minutes
    Rental::LATE_GRACE_MINUTES
  end

  def billable_overdue_hours
    rental.billable_overdue_hours
  end

  def late_hourly_rate
    rental.late_hourly_rate
  end

  def daily_rate_cap
    rental.daily_rate_cap
  end

  def late_fee_amount
    rental.late_fee_accrued
  end

  # ----------------------------------------------------------------
  # Aggregate
  # ----------------------------------------------------------------

  # Line items to persist as RentalCharge rows.
  def lines
    result = []

    if refueling_charge_amount.positive?
      result << {
        charge_type: 'refueling_charge',
        description: "Refueling surcharge (#{missing_fuel_gallons} gal missing @ $#{format('%.2f', refuel_price_per_gallon)}/gal)",
        unit_price: refuel_price_per_gallon,
        quantity: missing_fuel_gallons,
        amount: refueling_charge_amount
      }
    end

    if excess_mileage_charge_amount.positive?
      result << {
        charge_type: 'excess_mileage',
        description: "Excess mileage (#{excess_miles} mi @ $#{format('%.2f', excess_mileage_rate)}/mi)",
        unit_price: excess_mileage_rate,
        quantity: excess_miles,
        amount: excess_mileage_charge_amount
      }
    end

    if late_fee_amount.positive?
      result << {
        charge_type: 'late_return_fee',
        description: "Late return fee (#{billable_overdue_hours}h beyond the 60-minute grace @ $#{format('%.2f', late_hourly_rate)}/hr#{', capped at the daily rate' if rental.late_fee_capped?})",
        unit_price: late_hourly_rate,
        quantity: billable_overdue_hours,
        amount: late_fee_amount
      }
    end

    result
  end

  def surcharges_total
    lines.sum { |line| line[:amount] }.round(2)
  end

  def base_charges_total
    rental.rental_charges.kept.where.not(charge_type: %w[refueling_charge excess_mileage late_return_fee]).sum(:amount).to_d
  end

  def grand_total
    (base_charges_total + surcharges_total).round(2)
  end

  def deposit_hold_total
    rental.deposit_hold_total
  end

  def capture_amount
    [grand_total, deposit_hold_total].min.round(2)
  end

  def release_amount
    [deposit_hold_total - capture_amount, 0].max.round(2)
  end

  def balance_owed
    [grand_total - deposit_hold_total, 0].max.round(2)
  end

  # Explicit formula breakdown so the UI (and the reviewer) can verify the math.
  def formula_breakdown
    [
      { label: 'Refueling shortfall', formula: "#{missing_fuel_gallons} gal × $#{format('%.2f', refuel_price_per_gallon)}/gal", amount: refueling_charge_amount.to_f },
      { label: 'Excess mileage', formula: "#{excess_miles} mi × $#{format('%.2f', excess_mileage_rate)}/mi", amount: excess_mileage_charge_amount.to_f },
      { label: 'Late return', formula: "#{billable_overdue_hours}h × $#{format('%.2f', late_hourly_rate)}/hr (grace #{late_grace_minutes}m, cap $#{format('%.2f', daily_rate_cap)})", amount: late_fee_amount.to_f }
    ]
  end

  def summary
    {
      'fuel_variance_percentage' => fuel_variance_percentage.to_f,
      'missing_fuel_gallons' => missing_fuel_gallons.to_f,
      'refuel_price_per_gallon' => refuel_price_per_gallon.to_f,
      'refueling_charge' => refueling_charge_amount.to_f,
      'miles_driven' => miles_driven,
      'mileage_allowance' => mileage_allowance,
      'excess_miles' => excess_miles,
      'excess_mileage_charge' => excess_mileage_charge_amount.to_f,
      'late_grace_minutes' => late_grace_minutes,
      'billable_overdue_hours' => billable_overdue_hours,
      'late_hourly_rate' => late_hourly_rate.to_f,
      'late_fee_capped' => rental.late_fee_capped?,
      'late_fee' => late_fee_amount.to_f,
      'daily_cap' => daily_rate_cap.to_f,
      'base_charges' => base_charges_total.to_f,
      'surcharges_total' => surcharges_total.to_f,
      'grand_total' => grand_total.to_f,
      'deposit_hold' => deposit_hold_total.to_f,
      'capture_amount' => capture_amount.to_f,
      'release_amount' => release_amount.to_f,
      'balance_owed' => balance_owed.to_f,
      'formulas' => formula_breakdown
    }
  end

  # Persists the surcharge lines, replacing any previously computed ones, then
  # returns the resulting grand total.
  def persist!
    return BigDecimal('0') unless return_inspection || rental.inspections.kept.exists?

    ActiveRecord::Base.transaction do
      rental.rental_charges.kept
            .where(charge_type: %w[refueling_charge excess_mileage late_return_fee])
            .find_each(&:discard!)

      lines.each do |line|
        rental.rental_charges.create!(line.merge(organization_id: rental.organization_id))
      end

      rental.recalculate_totals!
    end

    grand_total
  end
end
