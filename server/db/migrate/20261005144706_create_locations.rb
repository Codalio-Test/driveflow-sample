# frozen_string_literal: true

class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name
      t.string :code
      t.string :address, null: true
      t.string :city, null: true
      t.string :state, null: true
      t.string :postal_code, null: true
      t.string :phone, null: true
      t.string :email, null: true
      t.boolean :is_active, default: true
      t.datetime :discarded_at
      t.index :discarded_at
      t.timestamps
    end
  end
end
