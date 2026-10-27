# frozen_string_literal: true

class AddDriveflowFieldsToCustomerProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :customer_profiles, :stripe_payment_method_token, :string
    add_column :customer_profiles, :card_last4, :string
    add_column :customer_profiles, :card_brand, :string
    add_column :customer_profiles, :email_verified, :boolean, null: false, default: false
  end
end
