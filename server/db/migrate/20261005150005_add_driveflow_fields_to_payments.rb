# frozen_string_literal: true

class AddDriveflowFieldsToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :stripe_refund_key, :string
    add_column :payments, :captured_amount, :decimal, precision: 10, scale: 2
    add_column :payments, :released_amount, :decimal, precision: 10, scale: 2
  end
end
