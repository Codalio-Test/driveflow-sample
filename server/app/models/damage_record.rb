# frozen_string_literal: true

class DamageRecord < Rhino::RhinoModel
  include Rhino::BelongsToOrganization
  include SoftDeletable

  SEVERITIES = %w[minor_scratch dent deep_gouge crack structural].freeze

  belongs_to :inspection
  belongs_to :vehicle

  # Close-up capture of the pinned blemish.
  has_one_attached :photo

  rhino_filters :inspection_id, :vehicle_id, :panel_location, :severity, :is_pre_existing, :repaired
  rhino_sorts :severity, :repair_cost_estimate, :created_at
  rhino_default_sort '-created_at'
  rhino_search :panel_location, :description
  rhino_fields :id, :inspection_id, :vehicle_id, :panel_location, :severity, :description,
               :photo_url, :is_pre_existing, :repair_cost_estimate, :repaired,
               :photo_taken_at, :dimensions, :captured_angle, :created_at
  rhino_includes :inspection, :vehicle
  rhino_pagination_enabled true
  rhino_per_page 25

  validates :panel_location, presence: true, length: { maximum: 255 }
  validates :severity, presence: true, inclusion: { in: SEVERITIES }
  validates :description, presence: true
  validates :is_pre_existing, inclusion: { in: [true, false] }
  validates :repaired, inclusion: { in: [true, false] }
  validates :repair_cost_estimate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :new_damage_requires_photo

  def new_damage?
    !is_pre_existing?
  end

  def rhino_computed_attributes
    {
      'label' => "#{panel_location} · #{severity.humanize}",
      'new_damage' => new_damage?,
      'photo' => photo_url,
      'cost' => repair_cost_estimate.to_d.to_f
    }
  end

  private

  def new_damage_requires_photo
    return if is_pre_existing?
    return if photo_url.present?

    errors.add(:photo_url, 'is required for newly discovered damage')
  end
end
