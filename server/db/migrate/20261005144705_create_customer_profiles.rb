# frozen_string_literal: true

class CreateCustomerProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :customer_profiles do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, foreign_key: true, null: true
      t.string :full_name, null: true
      t.string :email, null: true
      t.string :license_number, null: true
      t.string :license_state, null: true
      t.date :license_expiry_date, null: true
      t.string :license_country, null: true
      t.boolean :license_verified
      t.string :stripe_customer_token, null: true
      t.string :phone_number, null: true
      t.date :date_of_birth, null: true
      t.string :address, null: true
      t.datetime :discarded_at
      t.index :discarded_at
      t.timestamps
    end
  end
end
