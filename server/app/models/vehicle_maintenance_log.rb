# frozen_string_literal: true

class VehicleMaintenanceLog < Rhino::RhinoModel
  include Rhino::BelongsToOrganization
  include SoftDeletable

  SERVICE_TYPES = %w[oil_change tire_rotation brake_service inspection
                     battery replacement detailing other].freeze
  STATUSES = %w[scheduled in_progress completed cancelled].freeze

  belongs_to :vehicle
  belongs_to :user, optional: true

  rhino_filters :vehicle_id, :user_id, :service_type, :status
  rhino_sorts :service_date, :cost, :created_at
  rhino_default_sort '-service_date'
  rhino_search :service_type, :vendor_name, :notes
  rhino_fields :id, :vehicle_id, :user_id, :service_type, :service_date,
               :odometer_at_service, :cost, :vendor_name, :status, :notes, :created_at
  rhino_includes :vehicle, :user
  rhino_pagination_enabled true
  rhino_per_page 25

  validates :service_type, presence: true, inclusion: { in: SERVICE_TYPES }
  validates :service_date, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :odometer_at_service, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :cost, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :open_orders, -> { where(status: %w[scheduled in_progress]) }
  scope :completed, -> { where(status: 'completed') }

  after_commit :sync_vehicle_status, on: %i[create update]

  def rhino_computed_attributes
    {
      'vehicle' => vehicle ? "#{vehicle.license_plate} · #{vehicle.make} #{vehicle.model}" : nil,
      'plate' => vehicle&.license_plate,
      'service' => service_type.humanize,
      'progress' => vehicle ? vehicle.service_progress : nil,
      'detail' => service_detail,
      'priority' => maintenance_priority,
      'status_label' => status.humanize
    }
  end

  private

  def service_detail
    return nil unless vehicle && odometer_at_service

    delta = vehicle.current_odometer.to_i - odometer_at_service.to_i
    delta.positive? ? "#{delta} mi overdue" : "#{delta.abs} mi remaining"
  end

  def maintenance_priority
    return 'Low' unless vehicle
    return 'Critical' if vehicle.service_due?

    'High'
  end

  def sync_vehicle_status
    return unless vehicle

    if status == 'in_progress' || status == 'scheduled'
      vehicle.update_columns(status: 'maintenance', updated_at: Time.current)
    elsif status == 'completed' && vehicle.status == 'maintenance'
      vehicle.update_columns(
        status: 'available',
        current_odometer: [vehicle.current_odometer.to_i, odometer_at_service.to_i].max,
        last_service_odometer: [vehicle.last_service_odometer.to_i, odometer_at_service.to_i].max,
        updated_at: Time.current
      )
    end
  end
end
