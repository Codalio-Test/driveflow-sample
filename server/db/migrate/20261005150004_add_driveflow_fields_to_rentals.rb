# frozen_string_literal: true

class AddDriveflowFieldsToRentals < ActiveRecord::Migration[8.0]
  def change
    add_column :rentals, :agreement_signed_at, :datetime
    add_column :rentals, :agreement_signed_by_name, :string
    add_column :rentals, :extension_count, :integer, null: false, default: 0
    add_column :rentals, :escalated_for_recovery, :boolean, null: false, default: false
    add_column :rentals, :last_notified_at, :datetime
    add_column :rentals, :notes, :text
  end
end
