# frozen_string_literal: true

class Location < Rhino::RhinoModel
  include Rhino::BelongsToOrganization
  include SoftDeletable

  has_many :vehicles, dependent: :nullify
  has_many :rentals, dependent: :nullify

  rhino_filters :name, :code, :city, :state, :postal_code, :is_active
  rhino_sorts :name, :code, :city, :state, :created_at
  rhino_default_sort 'name'
  rhino_search :name, :code, :address, :city, :state, :postal_code
  rhino_fields :id, :name, :code, :address, :city, :state, :postal_code, :phone, :email, :is_active, :created_at
  rhino_includes :vehicles
  rhino_pagination_enabled true
  rhino_per_page 25

  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, length: { maximum: 255 }
  validates :postal_code, length: { maximum: 255 }, allow_nil: true
  validates :is_active, inclusion: { in: [true, false] }

  def rhino_computed_attributes
    {
      'label' => [code, name].compact.join(' · '),
      'vehicle_count' => vehicles.kept.count
    }
  end
end
