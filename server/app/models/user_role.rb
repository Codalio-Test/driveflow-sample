# frozen_string_literal: true

class UserRole < ApplicationRecord
  belongs_to :user
  # Nullable: non-tenant group memberships (e.g. a wildcard membership) carry
  # no organization.
  belongs_to :organization, optional: true
  belongs_to :role

  validates :role_id, uniqueness: { scope: %i[user_id organization_id] }
end
