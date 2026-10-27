# frozen_string_literal: true

class Inspection < Rhino::RhinoModel
  include Rhino::BelongsToOrganization
  # Soft deletes: the inspections table carries `discarded_at` and every
  # service/controller reads inspections through `.kept`.
  include SoftDeletable

  TYPES = %w[check_out check_in].freeze
  CLEANLINESS = %w[clean moderate dirty].freeze
  REQUIRED_PHOTO_ANGLES = %w[front driver_side rear passenger_side].freeze

  belongs_to :rental
  belongs_to :vehicle
  belongs_to :user, optional: true
  has_many :damage_records, dependent: :destroy

  # 4-quadrant walkaround captures plus the renter's signature image.
  has_many_attached :photos
  has_one_attached :signature_image

  rhino_filters :rental_id, :vehicle_id, :user_id, :inspection_type, :cleanliness_status
  rhino_sorts :performed_at, :created_at
  rhino_default_sort '-performed_at'
  rhino_search :notes
  rhino_fields :id, :rental_id, :vehicle_id, :user_id, :inspection_type, :odometer_reading,
               :fuel_percentage, :cleanliness_status, :customer_signature_url,
               :customer_signature_timestamp, :notes, :performed_at, :status, :created_at
  rhino_includes :rental, :vehicle, :damage_records
  rhino_pagination_enabled true
  rhino_per_page 25

  before_validation :default_performed_at, on: :create

  validates :inspection_type, presence: true, inclusion: { in: TYPES }
  validates :odometer_reading, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :fuel_percentage, numericality: { only_integer: true, in: 0..100 }, allow_nil: true
  validates :cleanliness_status, inclusion: { in: CLEANLINESS }, allow_nil: true
  validates :status, inclusion: { in: %w[in_progress completed] }
  # A walkaround may be saved as a draft at any point, but it cannot be
  # *completed* without the odometer and fuel readings the settlement engine
  # depends on (AC-49).
  validate :completed_requires_readings

  def check_out?
    inspection_type == 'check_out'
  end

  def check_in?
    inspection_type == 'check_in'
  end

  def damage_photos
    damage_records.where.not(photo_url: nil).pluck(:photo_url)
  end

  def rhino_computed_attributes
    {
      'type_label' => check_out? ? 'Departure' : 'Return',
      'odometer' => "#{odometer_reading.to_i} mi",
      'fuel' => "#{fuel_percentage.to_i}%",
      'damage_count' => damage_records.kept.count,
      'new_damage_count' => damage_records.kept.where(is_pre_existing: false).count,
      'photo_count' => damage_records.kept.where.not(photo_url: nil).count,
      'signed' => customer_signature_url.present?,
      'required_photo_angles' => REQUIRED_PHOTO_ANGLES
    }
  end

  private

  def completed_requires_readings
    return unless status == 'completed'

    if odometer_reading.blank?
      errors.add(:odometer_reading, 'is required to complete a walkaround')
    end
    return if fuel_percentage.present?

    errors.add(:fuel_percentage, 'is required to complete a walkaround')
  end

  def default_performed_at
    self.performed_at ||= Time.current
  end
end
