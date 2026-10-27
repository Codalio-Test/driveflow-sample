# frozen_string_literal: true

class User < Rhino::RhinoModel
  include Rhino::HasPermissions

  has_secure_password
  # Rhino's Bearer auth resolves the user with User.find_by_api_token(token).
  has_secure_token :api_token

  has_many :user_roles, dependent: :destroy
  has_many :organizations, through: :user_roles
  has_many :roles, through: :user_roles
  has_many :customer_profiles, dependent: :nullify
  has_many :inspections, dependent: :nullify
  has_many :vehicle_maintenance_logs, dependent: :nullify

  # Never leak credentials or tokens through the API.
  rhino_additional_hidden :api_token, :verification_token, :reset_password_token,
                          :password_digest, :reset_password_sent_at

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :approved, inclusion: { in: [true, false] }

  before_validation :derive_name

  scope :approved, -> { where(approved: true) }

  def display_name
    [first_name, last_name].compact_blank.join(' ').presence || name
  end

  def verified?
    email_verified_at.present?
  end

  def issue_verification_token!
    update_columns(
      verification_token: SecureRandom.urlsafe_base64(32),
      updated_at: Time.current
    )
    verification_token
  end

  def verify_email!
    update_columns(email_verified_at: Time.current, approved: true, verification_token: nil,
                   updated_at: Time.current)
  end

  def customer_profile_for(organization)
    customer_profiles.find_by(organization_id: organization&.id)
  end

  def full_name
    display_name
  end

  private

  def derive_name
    return if name.present?

    self.name = [first_name, last_name].compact_blank.join(' ').presence || email
  end
end
