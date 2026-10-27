# frozen_string_literal: true

class CreateVehicleMaintenanceLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :vehicle_maintenance_logs do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :vehicle, foreign_key: true
      t.references :user, foreign_key: true, null: true
      t.string :service_type
      t.date :service_date
      t.integer :odometer_at_service, null: true
      t.decimal :cost, precision: 10, scale: 2, null: true
      t.string :vendor_name, null: true
      t.string :status, default: "scheduled"
      t.text :notes, null: true
      t.datetime :discarded_at
      t.index :discarded_at
      t.timestamps
    end
  end
end
