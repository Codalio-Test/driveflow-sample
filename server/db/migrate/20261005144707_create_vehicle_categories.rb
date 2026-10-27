# frozen_string_literal: true

class CreateVehicleCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :vehicle_categories do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name
      t.string :code
      t.text :description, null: true
      t.decimal :base_daily_rate, precision: 10, scale: 2
      t.decimal :security_deposit_amount, precision: 10, scale: 2
      t.integer :mileage_allowance_per_day, null: true
      t.decimal :excess_mileage_rate, precision: 10, scale: 2, null: true
      t.decimal :late_hourly_fee, precision: 10, scale: 2, null: true
      t.integer :passenger_capacity, null: true
      t.integer :baggage_capacity, null: true
      t.string :transmission, null: true
      t.datetime :discarded_at
      t.index :discarded_at
      t.timestamps
    end
  end
end
