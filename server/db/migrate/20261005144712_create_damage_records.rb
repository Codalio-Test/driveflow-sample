# frozen_string_literal: true

class CreateDamageRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :damage_records do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :inspection, foreign_key: true
      t.references :vehicle, foreign_key: true
      t.string :panel_location
      t.string :severity
      t.text :description
      t.string :photo_url, null: true
      t.boolean :is_pre_existing
      t.decimal :repair_cost_estimate, precision: 10, scale: 2, null: true
      t.boolean :repaired
      t.datetime :discarded_at
      t.index :discarded_at
      t.timestamps
    end
  end
end
