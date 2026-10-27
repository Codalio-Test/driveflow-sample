# frozen_string_literal: true

class AddDriveflowFieldsToDamageRecords < ActiveRecord::Migration[8.0]
  def change
    add_column :damage_records, :photo_taken_at, :datetime
    add_column :damage_records, :photo_latitude, :decimal, precision: 10, scale: 6
    add_column :damage_records, :photo_longitude, :decimal, precision: 10, scale: 6
    add_column :damage_records, :dimensions, :string
    add_column :damage_records, :captured_angle, :string
  end
end
