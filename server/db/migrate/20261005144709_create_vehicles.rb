# frozen_string_literal: true

class CreateVehicles < ActiveRecord::Migration[8.0]
  def change
    create_table :vehicles do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :vehicle_category, foreign_key: true
      t.references :location, foreign_key: true
      t.string :vin
      t.string :license_plate
      t.string :make
      t.string :model
      t.integer :year
      t.string :color, null: true
      t.integer :current_odometer, default: 0
      t.integer :fuel_percentage, null: true
      t.string :fuel_type, null: true
      t.string :status, default: "available"
      t.datetime :discarded_at
      t.index :discarded_at
      t.timestamps
    end
  end
end
