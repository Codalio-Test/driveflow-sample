# frozen_string_literal: true

class Vehicle < Rhino::RhinoModel
  include Rhino::BelongsToOrganization
  include SoftDeletable

  STATUSES = %w[available reserved rented maintenance cleaning overdue].freeze
  SERVICE_DUE_THRESHOLD_MILES = 500

  belongs_to :vehicle_category
  belongs_to :location
  has_many :rentals, dependent: :nullify
  has_many :inspections, dependent: :nullify
  has_many :damage_records, dependent: :nullify
  has_many :vehicle_maintenance_logs, dependent: :nullify

  # Uploaded registration document (PDF, PNG or JPG).
  has_one_attached :registration_document

  rhino_filters :vehicle_category_id, :location_id, :vin, :license_plate, :make, :model,
                :year, :color, :fuel_type, :status
  rhino_sorts :license_plate, :make, :model, :year, :current_odometer, :status, :created_at
  rhino_default_sort 'license_plate'
  rhino_search :vin, :license_plate, :make, :model, :color
  rhino_fields :id, :vehicle_category_id, :location_id, :vin, :license_plate, :make, :model,
               :year, :color, :current_odometer, :fuel_percentage, :fuel_type, :status,
               :service_interval_miles, :last_service_odometer, :fuel_tank_capacity_gallons,
               :registration_expires_on, :created_at
  rhino_includes :vehicle_category, :location, :vehicle_maintenance_logs
  rhino_scopes :available, service_due: Scopes::VehicleServiceDueScope
  rhino_pagination_enabled true
  rhino_per_page 25

  validates :vin, presence: true, length: { maximum: 255 }
  validates :license_plate, presence: true, length: { maximum: 255 }
  validates :make, presence: true, length: { maximum: 255 }
  validates :model, presence: true, length: { maximum: 255 }
  validates :year, presence: true, numericality: { only_integer: true, greater_than: 1900 }
  validates :current_odometer, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :fuel_percentage, numericality: { only_integer: true, in: 0..100 }, allow_nil: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :vin, uniqueness: { scope: :organization_id, conditions: -> { kept } }
  validates :license_plate, uniqueness: { scope: :organization_id, conditions: -> { kept } }
  validates :service_interval_miles, numericality: { only_integer: true, greater_than: 0 }
  validates :fuel_tank_capacity_gallons, numericality: { greater_than: 0 }

  scope :available, -> { where(status: 'available') }

  def display_name
    [year, make, model].compact.join(' ')
  end

  def next_service_odometer
    last_service_odometer.to_i + service_interval_miles.to_i
  end

  def miles_until_service
    next_service_odometer - current_odometer.to_i
  end

  def service_due?
    miles_until_service <= SERVICE_DUE_THRESHOLD_MILES
  end

  # Percentage of the current service interval already consumed (0-100).
  def service_progress
    interval = service_interval_miles.to_i
    return 0 if interval.zero?

    consumed = current_odometer.to_i - last_service_odometer.to_i
    ((consumed.to_f / interval) * 100).round.clamp(0, 100)
  end

  # Remaining service life as a health percentage (100 = freshly serviced).
  def health_percentage
    (100 - service_progress).clamp(0, 100)
  end

  def available_for_rental?
    status == 'available' && !active_maintenance?
  end

  def active_maintenance?
    vehicle_maintenance_logs.kept.where(status: %w[scheduled in_progress]).exists?
  end

  def rhino_computed_attributes
    {
      'name' => display_name,
      'plate' => license_plate,
      'location' => location&.name,
      'miles' => "#{current_odometer.to_i} mi",
      'health' => health_percentage,
      'service_due' => service_due?,
      'next_service_odometer' => next_service_odometer,
      'miles_until_service' => miles_until_service,
      'service_progress' => service_progress,
      'service_label' => service_due? ? 'Service due' : 'Service ok',
      'maintenance_active' => active_maintenance?
    }
  end
end
