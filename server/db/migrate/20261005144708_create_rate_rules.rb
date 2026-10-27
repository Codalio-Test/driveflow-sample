# frozen_string_literal: true

class CreateRateRules < ActiveRecord::Migration[8.0]
  def change
    create_table :rate_rules do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :vehicle_category, foreign_key: true
      t.string :name
      t.string :season_name, null: true
      t.date :start_date, null: true
      t.date :end_date, null: true
      t.decimal :daily_multiplier, precision: 8, scale: 2
      t.decimal :weekend_multiplier, precision: 8, scale: 2
      t.integer :min_rental_days, default: 1
      t.boolean :is_active, default: true
      t.datetime :discarded_at
      t.index :discarded_at
      t.timestamps
    end
  end
end
