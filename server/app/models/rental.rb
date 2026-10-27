# frozen_string_literal: true

class Rental < Rhino::RhinoModel
  include Rhino::BelongsToOrganization
  include SoftDeletable

  # 60-minute grace period is authoritative everywhere (PRD gap FLOW_JOURNEY_MISMATCH).
  LATE_GRACE_MINUTES = 60
  STATUSES = %w[reserved confirmed active overdue completed cancelled].freeze
  PROTECTION_TIERS = %w[basic standard full].freeze
  ACTIVE_STATUSES = %w[reserved confirmed active].freeze

  belongs_to :customer_profile
  belongs_to :vehicle_category
  belongs_to :vehicle, optional: true
  belongs_to :location, optional: true

  has_many :inspections, dependent: :destroy
  has_many :rental_charges, dependent: :destroy
  has_many :payments, dependent: :nullify

  rhino_filters :customer_profile_id, :vehicle_category_id, :vehicle_id, :location_id,
                :reservation_number, :status, :protection_tier, :dropoff_location_code
  rhino_sorts :reservation_number, :pickup_datetime, :scheduled_return_datetime,
              :actual_return_datetime, :scheduled_duration_days, :status, :created_at
  rhino_default_sort '-pickup_datetime'
  rhino_search :reservation_number
  rhino_fields :id, :customer_profile_id, :vehicle_category_id, :vehicle_id, :location_id,
               :reservation_number, :pickup_datetime, :scheduled_return_datetime,
               :actual_return_datetime, :scheduled_duration_days, :status, :protection_tier,
               :initial_odometer, :final_odometer, :initial_fuel_percentage,
               :final_fuel_percentage, :total_charges_amount, :total_paid_amount,
               :balance_owed_amount, :dropoff_location_code, :created_at
  rhino_includes :customer_profile, :vehicle_category, :vehicle, :location, :rental_charges, :payments
  rhino_scopes :active, :overdue, with_balance_owed: :with_balance_owed
  rhino_pagination_enabled true
  rhino_per_page 25

  before_validation :generate_reservation_number, on: :create

  validates :reservation_number, presence: true, length: { maximum: 255 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :protection_tier, presence: true, inclusion: { in: PROTECTION_TIERS }
  validates :scheduled_duration_days, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :total_charges_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :total_paid_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :balance_owed_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :return_after_pickup

  scope :active, -> { where(status: %w[confirmed active]) }
  scope :overdue, -> { where(status: 'overdue') }
  scope :with_balance_owed, -> { where('balance_owed_amount > 0') }

  def self.rhino_collection_computed_attributes
    {
      'overdue_count' => ->(scope, _user) { scope.where(status: 'overdue').count },
      'active_count' => ->(scope, _user) { scope.where(status: %w[confirmed active]).count },
      'balance_owed_total' => ->(scope, _user) { scope.where('balance_owed_amount > 0').sum(:balance_owed_amount).to_f }
    }
  end

  # ----------------------------------------------------------------
  # Late return / grace arithmetic (60-minute grace, hourly fee capped
  # at the daily rate).
  # ----------------------------------------------------------------

  def grace_period
    LATE_GRACE_MINUTES.minutes
  end

  def grace_expires_at
    return nil if scheduled_return_datetime.blank?

    scheduled_return_datetime + grace_period
  end

  def reference_return_time
    actual_return_datetime || Time.current
  end

  def beyond_grace?
    return false if grace_expires_at.blank?

    reference_return_time > grace_expires_at
  end

  def overdue_seconds
    return 0 unless beyond_grace?

    (reference_return_time - grace_expires_at).to_f
  end

  def billable_overdue_hours
    (overdue_seconds / 3600.0).round(2)
  end

  def late_hourly_rate
    vehicle_category&.late_hourly_fee.presence&.to_d || BigDecimal('18.00')
  end

  # Late fee is billed hourly but can never exceed one full daily rate.
  def daily_rate_cap
    return BigDecimal('0') unless vehicle_category

    RateCalculator.new(vehicle_category).daily_rate(pickup_datetime&.to_date || Date.current)
  end

  def late_fee_accrued
    return BigDecimal('0') unless beyond_grace?

    raw = (late_hourly_rate * BigDecimal(billable_overdue_hours.to_s)).round(2)
    [raw, daily_rate_cap].min
  end

  def late_fee_capped?
    return false unless beyond_grace?

    (late_hourly_rate * BigDecimal(billable_overdue_hours.to_s)).round(2) > daily_rate_cap
  end

  def overdue_duration_label
    return nil unless beyond_grace?

    total_minutes = (overdue_seconds / 60.0).round
    hours = total_minutes / 60
    minutes = total_minutes % 60
    hours.zero? ? "#{minutes}m" : "#{hours}h #{minutes}m"
  end

  # ----------------------------------------------------------------
  # Deposit / balance helpers
  # ----------------------------------------------------------------

  def deposit_hold_total
    payments.where(transaction_type: 'deposit_hold', status: 'succeeded').sum(:amount).to_d
  end

  def deposit_captured_total
    payments.where(transaction_type: 'deposit_capture').sum(:amount).to_d
  end

  def deposit_released_total
    payments.where(transaction_type: 'deposit_release').sum(:amount).to_d
  end

  def deposit_status
    if payments.where(transaction_type: 'deposit_capture', status: 'succeeded').exists?
      deposit_released_total.positive? ? 'Partially Refunded' : 'Captured'
    elsif payments.where(transaction_type: 'deposit_release', status: 'succeeded').exists?
      'Released'
    elsif payments.where(transaction_type: 'deposit_hold', status: 'succeeded').exists?
      'Held'
    else
      'Unsecured'
    end
  end

  def recalculate_totals!
    charges_total = rental_charges.kept.sum(:amount).to_d
    paid_total = payments.where(status: 'succeeded').where.not(transaction_type: %w[deposit_hold deposit_release]).sum(:amount).to_d
    update_columns(
      total_charges_amount: charges_total,
      total_paid_amount: paid_total,
      balance_owed_amount: [(charges_total - paid_total), 0].max,
      updated_at: Time.current
    )
  end

  def rhino_computed_attributes
    {
      'customer' => customer_profile&.full_name.presence || customer_profile&.email,
      'vehicle' => vehicle_label,
      'category' => vehicle_category&.name,
      'due' => formatted_return_time,
      'time' => formatted_return_time,
      'dates' => date_window_label,
      'accrued' => "$#{format('%.2f', late_fee_accrued)}",
      'late_fee_accrued' => late_fee_accrued.to_f,
      'late_fee_capped' => late_fee_capped?,
      'late_hourly_rate' => late_hourly_rate.to_f,
      'late_grace_minutes' => LATE_GRACE_MINUTES,
      'grace_expires_at' => grace_expires_at&.iso8601,
      'billable_overdue_hours' => billable_overdue_hours,
      'overdue_duration' => overdue_duration_label,
      'overdue' => beyond_grace?,
      'daily_cap' => daily_rate_cap.to_f,
      'balance' => "$#{format('%.2f', balance_owed_amount.to_d)}",
      'deposit_status' => deposit_status,
      'qr_code_url' => QrCodeService.new(self).data_uri,
      'reference' => reservation_number
    }
  end

  private

  def vehicle_label
    if vehicle
      "#{vehicle.make} #{vehicle.model} · #{vehicle.license_plate}"
    else
      vehicle_category&.name
    end
  end

  def formatted_return_time
    return nil if scheduled_return_datetime.blank?

    time = scheduled_return_datetime
    day = if time.to_date == Date.current
            'Today'
          elsif time.to_date == Date.current + 1
            'Tomorrow'
          else
            time.strftime('%b %-d')
          end
    "#{day} #{time.strftime('%-I:%M %p')}"
  end

  def date_window_label
    return nil if pickup_datetime.blank? || scheduled_return_datetime.blank?

    from = pickup_datetime.strftime('%b %-d')
    to = scheduled_return_datetime.strftime('%b %-d')
    "#{from}–#{to}"
  end

  def generate_reservation_number
    return if reservation_number.present?

    self.reservation_number = "DF-#{Time.current.year}-#{format('%04d', SecureRandom.random_number(10_000))}"
  end

  def return_after_pickup
    return if pickup_datetime.blank? || scheduled_return_datetime.blank?
    return if scheduled_return_datetime > pickup_datetime

    errors.add(:scheduled_return_datetime, 'must be after the pickup time')
  end
end
