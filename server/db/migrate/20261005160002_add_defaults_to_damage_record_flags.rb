# frozen_string_literal: true

# `damage_records.repaired` and `is_pre_existing` are non-null booleans with an
# inclusion validator, but the generated migration left them without a DB
# default — so any create that omits them (a fresh damage pin from the tablet
# walkaround, which only sends the panel + severity) produced `nil` and failed
# validation. Default them to false, matching "new damage, not yet repaired".
class AddDefaultsToDamageRecordFlags < ActiveRecord::Migration[8.1]
  def change
    change_column_default :damage_records, :repaired, from: nil, to: false
    change_column_default :damage_records, :is_pre_existing, from: nil, to: false

    change_column_null :damage_records, :repaired, false, false
    change_column_null :damage_records, :is_pre_existing, false, false
  end
end
