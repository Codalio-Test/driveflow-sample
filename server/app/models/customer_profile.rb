# frozen_string_literal: true

class CustomerProfile < Rhino::RhinoModel
  include Rhino::BelongsToOrganization
  include SoftDeletable

  # user_id is nullable: guest renters have no account (gap DATA_MODEL_UX_MISMATCH).
  belongs_to :user, optional: true
  has_many :rentals, dependent: :restrict_with_error
  has_many :payments, dependent: :nullify

  # Uploaded driver-license image / PDF (PNG, JPG or PDF).
  has_one_attached :driver_license

  rhino_filters :user_id, :email, :license_state, :license_country, :license_verified
  rhino_sorts :full_name, :license_expiry_date, :created_at
  rhino_default_sort 'full_name'
  rhino_search :full_name, :email, :license_number, :phone_number, :address
  rhino_fields :id, :user_id, :full_name, :email, :license_number, :license_state,
               :license_expiry_date, :license_country, :license_verified, :phone_number,
               :date_of_birth, :address, :created_at
  rhino_includes :user, :rentals, :payments
  rhino_pagination_enabled true
  rhino_per_page 25

  validates :full_name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: false
  validates :license_expiry_date, comparison: { greater_than: Date.new(1900, 1, 1) }, allow_nil: true

  scope :verified, -> { where(license_verified: true) }

  def guest?
    user_id.nil?
  end

  def license_expired?(on_date = Date.current)
    license_expiry_date.present? && license_expiry_date < on_date
  end

  # Positive form used by the counter check-out gate (AC-31).
  def license_valid?
    !license_expired?
  end

  def rhino_computed_attributes
    {
      'rental_count' => rentals.kept.count,
      'guest' => guest?,
      'license_expired' => license_expired?,
      'license_valid' => !license_expired?,
      'card_last4' => card_last4,
      'card_brand' => card_brand
    }
  end
end
