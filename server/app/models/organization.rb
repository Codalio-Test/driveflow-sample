# frozen_string_literal: true

class Organization < ApplicationRecord
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles
  has_many :roles, through: :user_roles

  has_many :org_role_permissions, dependent: :destroy
  has_many :locations, dependent: :destroy
  has_many :vehicle_categories, dependent: :destroy
  has_many :rate_rules, dependent: :destroy
  has_many :customer_profiles, dependent: :destroy
  has_many :vehicles, dependent: :destroy
  has_many :vehicle_maintenance_logs, dependent: :destroy
  has_many :rentals, dependent: :destroy
  has_many :inspections, dependent: :destroy
  has_many :rental_charges, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :damage_records, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  def member?(user)
    return false unless user

    user.user_roles.exists?(organization_id: id)
  end

  private

  def generate_slug
    self.slug ||= name&.parameterize
  end
end
