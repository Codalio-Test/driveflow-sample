# frozen_string_literal: true

class CreateRentals < ActiveRecord::Migration[8.0]
  def change
    create_table :rentals do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :customer_profile, foreign_key: true
      t.references :vehicle_category, foreign_key: true
      t.references :vehicle, foreign_key: true, null: true
      t.references :location, foreign_key: true, null: true
      t.string :reservation_number
      t.datetime :pickup_datetime, null: true
      t.datetime :scheduled_return_datetime, null: true
      t.datetime :actual_return_datetime, null: true
      t.integer :scheduled_duration_days, null: true
      t.string :status, default: "reserved"
      t.string :protection_tier, default: "basic"
      t.integer :initial_odometer, null: true
      t.integer :final_odometer, null: true
      t.integer :initial_fuel_percentage, null: true
      t.integer :final_fuel_percentage, null: true
      t.decimal :total_charges_amount, precision: 10, scale: 2
      t.decimal :total_paid_amount, precision: 10, scale: 2
      t.decimal :balance_owed_amount, precision: 10, scale: 2
      t.string :dropoff_location_code, null: true
      t.datetime :discarded_at
      t.index :discarded_at
      t.timestamps
    end
  end
end
