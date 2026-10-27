# frozen_string_literal: true

# Resolves the effective daily rate for a vehicle category on a given date,
# applying the best-matching active seasonal rate rule.
class RateCalculator
  # Premium per-gallon refueling rate applied to fuel shortfalls (AC-9/AC-27).
  DEFAULT_REFUEL_PRICE_PER_GALLON = BigDecimal('8.00')
  DEFAULT_LATE_HOURLY_FEE = BigDecimal('18.00')

  attr_reader :vehicle_category

  def initialize(vehicle_category)
    @vehicle_category = vehicle_category
  end

  def daily_rate(on_date = Date.current)
    base = vehicle_category.base_daily_rate.to_d
    rule = matching_rule(on_date)
    return base.round(2) if rule.nil?

    (base * rule.daily_multiplier.to_d).round(2)
  end

  def weekend_rate(on_date = Date.current)
    base = vehicle_category.base_daily_rate.to_d
    rule = matching_rule(on_date)
    multiplier = rule ? rule.weekend_multiplier.to_d : BigDecimal('1')
    (base * multiplier).round(2)
  end

  def late_hourly_fee
    vehicle_category.late_hourly_fee.presence&.to_d || DEFAULT_LATE_HOURLY_FEE
  end

  def excess_mileage_rate
    vehicle_category.excess_mileage_rate.to_d
  end

  def mileage_allowance_per_day
    vehicle_category.mileage_allowance_per_day.to_i
  end

  class << self
    # Organization-configured premium refueling rate (falls back to $8.00/gal).
    def refuel_price_per_gallon(organization = nil)
      return DEFAULT_REFUEL_PRICE_PER_GALLON unless organization

      rule = RateRule.where(organization_id: organization.id, season_name: 'refueling_rate')
                     .where(is_active: true).first
      rule&.daily_multiplier&.to_d || DEFAULT_REFUEL_PRICE_PER_GALLON
    end

    # Organization-configured late return hourly fee (falls back to $18.00/hr).
    def late_hourly_fee(organization = nil)
      return DEFAULT_LATE_HOURLY_FEE unless organization

      rule = RateRule.where(organization_id: organization.id, season_name: 'late_return_fee')
                     .where(is_active: true).first
      rule&.daily_multiplier&.to_d || DEFAULT_LATE_HOURLY_FEE
    end
  end

  private

  def matching_rule(on_date)
    return nil unless vehicle_category.respond_to?(:rate_rules)

    vehicle_category.rate_rules.kept.where(is_active: true).detect do |rule|
      (rule.start_date.nil? || rule.start_date <= on_date) &&
        (rule.end_date.nil? || rule.end_date >= on_date)
    end
  end
end
