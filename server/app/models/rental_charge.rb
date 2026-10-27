# frozen_string_literal: true

class RentalCharge < Rhino::RhinoModel
  include Rhino::BelongsToOrganization
  include SoftDeletable

  CHARGE_TYPES = %w[
    base_rate insurance_protection equipment_addon excess_mileage
    refueling_charge late_return_fee damage_claim sales_tax
  ].freeze

  belongs_to :rental

  rhino_filters :rental_id, :charge_type
  rhino_sorts :charge_type, :amount, :created_at
  rhino_default_sort 'created_at'
  rhino_search :description
  rhino_fields :id, :rental_id, :charge_type, :description, :unit_price, :quantity, :amount, :created_at
  rhino_includes :rental
  rhino_pagination_enabled true
  rhino_per_page 50

  validates :charge_type, presence: true, inclusion: { in: CHARGE_TYPES }
  validates :description, presence: true, length: { maximum: 255 }
  validates :amount, presence: true, numericality: true
  validates :unit_price, numericality: true, allow_nil: true
  validates :quantity, numericality: true, allow_nil: true

  after_commit :refresh_rental_totals, on: %i[create update]

  scope :for_rental, ->(rental_id) { where(rental_id: rental_id) }

  def rhino_computed_attributes
    {
      'total' => amount.to_d.to_f,
      'label' => description,
      'category' => charge_type.humanize
    }
  end

  private

  def refresh_rental_totals
    rental&.recalculate_totals!
  end
end
