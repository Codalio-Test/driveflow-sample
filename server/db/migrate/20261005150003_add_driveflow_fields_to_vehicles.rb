# frozen_string_literal: true

class AddDriveflowFieldsToVehicles < ActiveRecord::Migration[8.0]
  def change
    add_column :vehicles, :service_interval_miles, :integer, null: false, default: 5000
    add_column :vehicles, :last_service_odometer, :integer, null: false, default: 0
    add_column :vehicles, :fuel_tank_capacity_gallons, :decimal, precision: 8, scale: 2, null: false, default: "14.00"
    add_column :vehicles, :registration_expires_on, :date
    add_column :vehicles, :acquired_on, :date
  end
end
