# frozen_string_literal: true

class RateRule < Rhino::RhinoModel
  include Rhino::BelongsToOrganization
  include SoftDeletable

  belongs_to :vehicle_category

  rhino_filters :vehicle_category_id, :name, :season_name, :is_active
  rhino_sorts :name, :season_name, :start_date, :end_date, :daily_multiplier, :created_at
  rhino_default_sort 'name'
  rhino_search :name, :season_name
  rhino_fields :id, :vehicle_category_id, :name, :season_name, :start_date, :end_date,
               :daily_multiplier, :weekend_multiplier, :min_rental_days, :is_active, :created_at
  rhino_includes :vehicle_category
  rhino_pagination_enabled true
  rhino_per_page 50

  validates :name, presence: true, length: { maximum: 255 }
  validates :daily_multiplier, presence: true, numericality: { greater_than: 0 }
  validates :weekend_multiplier, presence: true, numericality: { greater_than: 0 }
  validates :min_rental_days, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :is_active, inclusion: { in: [true, false] }
  validate :end_date_after_start_date

  scope :active, -> { where(is_active: true) }
  scope :current, lambda {
    today = Date.current
    where(is_active: true)
      .where('(start_date IS NULL OR start_date <= ?)', today)
      .where('(end_date IS NULL OR end_date >= ?)', today)
  }

  def self.rhino_collection_computed_attributes
    {
      'active_count' => ->(scope, _user) { scope.where(is_active: true).count }
    }
  end

  def rhino_computed_attributes
    {
      # Prototype `/admin/rates` reads name / scope / value / priority.
      'scope' => [vehicle_category&.name || 'All classes', season_name.presence].compact.join(' · '),
      'value' => display_value,
      'priority' => display_priority,
      'rule_type' => display_priority.downcase
    }
  end

  def fee_schedule?
    season_name.to_s.in?(%w[refueling_rate late_return_fee excess_mileage])
  end

  def display_priority
    return 'Fee' if season_name.to_s == 'refueling_rate'
    return 'Penalty' if season_name.to_s == 'late_return_fee'
    # A full-price year-round rule is the base rate card, not a seasonal surge.
    return 'Base' if daily_multiplier.to_d == 1.to_d ||
                     season_name.to_s.in?(%w[regular base standard standard_ev])

    'Seasonal'
  end

  def display_value
    if season_name.to_s == 'refueling_rate'
      "$#{format('%.2f', daily_multiplier)}/gal"
    elsif season_name.to_s == 'late_return_fee'
      "$#{format('%.2f', daily_multiplier)}/hr"
    elsif daily_multiplier.to_d != 1.to_d
      multiplier_label(daily_multiplier)
    else
      "$#{format('%.2f', vehicle_category&.base_daily_rate || 0)}/day"
    end
  end

  private

  def multiplier_label(multiplier)
    delta = ((multiplier.to_d - 1.to_d) * 100).round(1)
    "#{delta.positive? ? '+' : ''}#{delta}%"
  end

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, 'must be on or after the start date')
  end
end
