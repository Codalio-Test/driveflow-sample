# frozen_string_literal: true

class CreateRentalCharges < ActiveRecord::Migration[8.0]
  def change
    create_table :rental_charges do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :rental, foreign_key: true
      t.string :charge_type
      t.string :description
      t.decimal :unit_price, precision: 10, scale: 2, null: true
      t.decimal :quantity, precision: 10, scale: 2, null: true
      t.decimal :amount, precision: 10, scale: 2
      t.datetime :discarded_at
      t.index :discarded_at
      t.timestamps
    end
  end
end
