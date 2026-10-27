# frozen_string_literal: true

# Builds the itemized charge lines for a reservation: base rate, protection
# tier, add-ons and sales tax. Protection tiers and add-ons are persisted as
# RentalCharge rows (PRD gap DATA_MODEL_UX_MISMATCH).
class BookingChargeService
  SALES_TAX_RATE = BigDecimal('0.065')

  PROTECTION_TIERS = {
    'basic' => { label: 'Basic', price_per_day: BigDecimal('0') },
    'standard' => { label: 'Standard', price_per_day: BigDecimal('12') },
    'full' => { label: 'Full', price_per_day: BigDecimal('24') }
  }.freeze

  ADDONS = {
    'additional_driver' => { label: 'Additional driver', price_per_day: BigDecimal('10') },
    'child_seat' => { label: 'Child safety seat', price_per_day: BigDecimal('8') },
    'roadside_assistance' => { label: 'Roadside assistance', price_per_day: BigDecimal('6') },
    'prepaid_fuel' => { label: 'Prepaid fuel', price_per_day: BigDecimal('0') }
  }.freeze

  attr_reader :rental

  def initialize(rental)
    @rental = rental
  end

  def call(addons: nil)
    days = rental.scheduled_duration_days.to_i
    days = 1 if days <= 0
    category = rental.vehicle_category
    rate = RateCalculator.new(category).daily_rate(rental.pickup_datetime&.to_date || Date.current)

    lines = []
    lines << { charge_type: 'base_rate', description: "#{category.name} #{days}-day base rental",
               unit_price: rate, quantity: days, amount: (rate * days).round(2) }

    tier = PROTECTION_TIERS[rental.protection_tier] || PROTECTION_TIERS['basic']
    if tier[:price_per_day].positive?
      lines << { charge_type: 'insurance_protection',
                 description: "#{tier[:label]} protection #{money(tier[:price_per_day])}/day",
                 unit_price: tier[:price_per_day], quantity: days,
                 amount: (tier[:price_per_day] * days).round(2) }
    end

    (addons || addon_keys).each do |key|
      addon = ADDONS[key]
      next unless addon

      lines << { charge_type: 'equipment_addon', description: addon[:label],
                 unit_price: addon[:price_per_day], quantity: days,
                 amount: (addon[:price_per_day] * days).round(2) }
    end

    subtotal = lines.sum { |l| l[:amount] }
    tax = (subtotal * SALES_TAX_RATE).round(2)
    lines << { charge_type: 'sales_tax', description: 'State and municipal vehicle rental tax',
               unit_price: tax, quantity: 1, amount: tax }

    lines
  end

  # Replaces the rental's rate/tier/add-on lines with a freshly computed set,
  # leaving surcharge lines (refueling, late, damage, mileage) untouched.
  def persist!
    preserve = %w[refueling_charge late_return_fee damage_claim excess_mileage]
    # Capture the renter's add-on selection BEFORE dropping the existing rows —
    # the selection is stored as equipment_addon charges, so it would otherwise
    # be lost when the old lines are discarded.
    selected_addons = addon_keys
    rental.rental_charges.kept.where.not(charge_type: preserve).find_each(&:discard!)

    call(addons: selected_addons).each do |line|
      rental.rental_charges.create!(line.merge(organization_id: rental.organization_id))
    end

    rental.recalculate_totals!
    rental.rental_charges.kept.sum(:amount).to_d
  end

  def self.tier_options
    PROTECTION_TIERS.map { |key, cfg| { name: cfg[:label], copy: tier_copy(key), price: cfg[:price_per_day].to_f } }
  end

  def self.addon_options
    ADDONS.map { |key, cfg| { name: cfg[:label], key: key, price: cfg[:price_per_day].to_f } }
  end

  def self.tier_copy(key)
    case key
    when 'standard' then 'Balanced protection'
    when 'full' then 'Maximum confidence'
    else 'Essential coverage'
    end
  end

  private

  def addon_keys
    rental.rental_charges.kept.where(charge_type: 'equipment_addon').map do |charge|
      ADDONS.keys.detect { |key| ADDONS[key][:label] == charge.description } || charge.description
    end
  end

  def money(value)
    "$#{format('%.2f', value)}"
  end
end
