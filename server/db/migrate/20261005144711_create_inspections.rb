# frozen_string_literal: true

class CreateInspections < ActiveRecord::Migration[8.0]
  def change
    create_table :inspections do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :rental, foreign_key: true
      t.references :vehicle, foreign_key: true
      t.references :user, foreign_key: true, null: true
      t.string :inspection_type
      t.integer :odometer_reading, null: true
      t.integer :fuel_percentage, null: true
      t.string :cleanliness_status, null: true
      t.string :customer_signature_url, null: true
      t.datetime :customer_signature_timestamp, null: true
      t.text :notes, null: true
      t.datetime :performed_at, null: true
      t.datetime :discarded_at
      t.index :discarded_at
      t.timestamps
    end
  end
end
