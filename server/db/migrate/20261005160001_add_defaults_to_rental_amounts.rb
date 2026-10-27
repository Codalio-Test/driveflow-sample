# frozen_string_literal: true

# The rentals blueprint declares `default: "0.00"` for the three money columns
# but the generated migration omitted them, so a freshly built Rental is
# invalid (nil is not a number) on every create path — booking, counter and
# seeds alike. Restore the blueprint's DB defaults.
class AddDefaultsToRentalAmounts < ActiveRecord::Migration[8.1]
  def change
    change_column_default :rentals, :total_charges_amount, from: nil, to: '0.00'
    change_column_default :rentals, :total_paid_amount, from: nil, to: '0.00'
    change_column_default :rentals, :balance_owed_amount, from: nil, to: '0.00'

    change_column_null :rentals, :total_charges_amount, false, 0
    change_column_null :rentals, :total_paid_amount, false, 0
    change_column_null :rentals, :balance_owed_amount, false, 0
  end
end
