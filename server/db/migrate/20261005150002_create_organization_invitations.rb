# frozen_string_literal: true

# Backs Rhino::OrganizationInvitation (lib/rhino/models/organization_invitation.rb),
# whose routes are drawn by the engine's tenant group.
class CreateOrganizationInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :organization_invitations do |t|
      t.references :organization, null: true, foreign_key: true
      t.references :role, null: true, foreign_key: true
      t.integer :invited_by, null: true
      t.string :route_group
      t.string :email, null: false
      t.string :token, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :expires_at
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :organization_invitations, :token, unique: true
    add_index :organization_invitations, :email
  end
end
