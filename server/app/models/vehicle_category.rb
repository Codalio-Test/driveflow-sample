# frozen_string_literal: true

class VehicleCategory < Rhino::RhinoModel
  include Rhino::BelongsToOrganization
  include SoftDeletable

  has_many :vehicles, dependent: :restrict_with_error
  has_many :rate_rules, dependent: :destroy
  has_many :rentals, dependent: :restrict_with_error

  rhino_filters :name, :code, :transmission
  rhino_sorts :name, :code, :base_daily_rate, :created_at
  rhino_default_sort 'base_daily_rate'
  rhino_search :name, :code, :description
  rhino_fields :id, :name, :code, :description, :base_daily_rate, :security_deposit_amount,
               :mileage_allowance_per_day, :excess_mileage_rate, :late_hourly_fee,
               :passenger_capacity, :baggage_capacity, :transmission, :created_at
  rhino_includes :vehicles, :rate_rules
  rhino_pagination_enabled true
  rhino_per_page 25

  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, length: { maximum: 255 }
  validates :base_daily_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :security_deposit_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :excess_mileage_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :late_hourly_fee, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :mileage_allowance_per_day, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :passenger_capacity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :baggage_capacity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :transmission, inclusion: { in: %w[automatic manual] }, allow_nil: true

  # Effective daily rate for a given date, honouring active seasonal rate rules.
  def effective_daily_rate(on_date = Date.current)
    RateCalculator.new(self).daily_rate(on_date)
  end

  def rhino_computed_attributes
    {
      # Prototype `/booking` reads `name` + numeric `rate`.
      'rate' => effective_daily_rate.to_f,
      # Prototype `/vehicles` renders the class card plus its member vehicles.
      'vehicles' => vehicles.kept.map do |v|
        { 'id' => v.id, 'make' => v.make, 'model' => v.model, 'status' => v.status,
          'license_plate' => v.license_plate }
      end,
      'vehicle_count' => vehicles.kept.count,
      'available_vehicle_count' => vehicles.kept.where(status: 'available').count
    }
  end
end
