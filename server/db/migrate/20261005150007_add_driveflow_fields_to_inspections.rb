# frozen_string_literal: true

class AddDriveflowFieldsToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :status, :string, null: false, default: "in_progress"
    add_column :inspections, :checked_in_at, :datetime
  end
end
