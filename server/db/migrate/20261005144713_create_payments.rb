# frozen_string_literal: true

class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :rental, foreign_key: true
      t.references :customer_profile, foreign_key: true, null: true
      t.string :stripe_payment_intent_key, null: true
      t.string :stripe_charge_key, null: true
      t.string :transaction_type
      t.decimal :amount, precision: 10, scale: 2
      t.string :status, default: "pending"
      t.string :payment_method_last4, null: true
      t.datetime :processed_at, null: true
      t.string :notes, null: true
      t.datetime :discarded_at
      t.index :discarded_at
      t.timestamps
    end
  end
end
