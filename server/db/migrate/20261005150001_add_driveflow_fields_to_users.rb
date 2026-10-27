# frozen_string_literal: true

class AddDriveflowFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :api_token, :string
    add_index :users, :api_token, unique: true

    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :phone_number, :string
    add_column :users, :approved, :boolean, null: false, default: false
    add_column :users, :email_verified_at, :datetime
    add_column :users, :verification_token, :string
    add_index :users, :verification_token

    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime
    add_index :users, :reset_password_token
  end
end
