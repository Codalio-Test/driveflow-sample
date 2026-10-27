# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_05_160002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "auditable_type", null: false
    t.bigint "auditable_id", null: false
    t.string "action", null: false
    t.json "old_values"
    t.json "new_values"
    t.bigint "user_id"
    t.string "user_type"
    t.string "ip_address"
    t.string "user_agent"
    t.bigint "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["organization_id"], name: "index_audit_logs_on_organization_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "customer_profiles", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "user_id"
    t.string "full_name"
    t.string "email"
    t.string "license_number"
    t.string "license_state"
    t.date "license_expiry_date"
    t.string "license_country"
    t.boolean "license_verified"
    t.string "stripe_customer_token"
    t.string "phone_number"
    t.date "date_of_birth"
    t.string "address"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stripe_payment_method_token"
    t.string "card_last4"
    t.string "card_brand"
    t.boolean "email_verified", default: false, null: false
    t.index ["discarded_at"], name: "index_customer_profiles_on_discarded_at"
    t.index ["organization_id"], name: "index_customer_profiles_on_organization_id"
    t.index ["user_id"], name: "index_customer_profiles_on_user_id"
  end

  create_table "damage_records", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "inspection_id"
    t.bigint "vehicle_id"
    t.string "panel_location"
    t.string "severity"
    t.text "description"
    t.string "photo_url"
    t.boolean "is_pre_existing", default: false, null: false
    t.decimal "repair_cost_estimate", precision: 10, scale: 2
    t.boolean "repaired", default: false, null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "photo_taken_at"
    t.decimal "photo_latitude", precision: 10, scale: 6
    t.decimal "photo_longitude", precision: 10, scale: 6
    t.string "dimensions"
    t.string "captured_angle"
    t.index ["discarded_at"], name: "index_damage_records_on_discarded_at"
    t.index ["inspection_id"], name: "index_damage_records_on_inspection_id"
    t.index ["organization_id"], name: "index_damage_records_on_organization_id"
    t.index ["vehicle_id"], name: "index_damage_records_on_vehicle_id"
  end

  create_table "inspections", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "rental_id"
    t.bigint "vehicle_id"
    t.bigint "user_id"
    t.string "inspection_type"
    t.integer "odometer_reading"
    t.integer "fuel_percentage"
    t.string "cleanliness_status"
    t.string "customer_signature_url"
    t.datetime "customer_signature_timestamp"
    t.text "notes"
    t.datetime "performed_at"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "in_progress", null: false
    t.datetime "checked_in_at"
    t.index ["discarded_at"], name: "index_inspections_on_discarded_at"
    t.index ["organization_id"], name: "index_inspections_on_organization_id"
    t.index ["rental_id"], name: "index_inspections_on_rental_id"
    t.index ["user_id"], name: "index_inspections_on_user_id"
    t.index ["vehicle_id"], name: "index_inspections_on_vehicle_id"
  end

  create_table "locations", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name"
    t.string "code"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.string "phone"
    t.string "email"
    t.boolean "is_active", default: true
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_locations_on_discarded_at"
    t.index ["organization_id"], name: "index_locations_on_organization_id"
  end

  create_table "org_role_permissions", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "role_id", null: false
    t.json "permissions", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "role_id"], name: "index_org_role_permissions_on_org_role", unique: true
    t.index ["organization_id"], name: "index_org_role_permissions_on_organization_id"
    t.index ["role_id"], name: "index_org_role_permissions_on_role_id"
  end

  create_table "organization_invitations", force: :cascade do |t|
    t.bigint "organization_id"
    t.bigint "role_id"
    t.integer "invited_by"
    t.string "route_group"
    t.string "email", null: false
    t.string "token", null: false
    t.string "status", default: "pending", null: false
    t.datetime "expires_at"
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_organization_invitations_on_email"
    t.index ["organization_id"], name: "index_organization_invitations_on_organization_id"
    t.index ["role_id"], name: "index_organization_invitations_on_role_id"
    t.index ["token"], name: "index_organization_invitations_on_token", unique: true
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "rental_id"
    t.bigint "customer_profile_id"
    t.string "stripe_payment_intent_key"
    t.string "stripe_charge_key"
    t.string "transaction_type"
    t.decimal "amount", precision: 10, scale: 2
    t.string "status", default: "pending"
    t.string "payment_method_last4"
    t.datetime "processed_at"
    t.string "notes"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stripe_refund_key"
    t.decimal "captured_amount", precision: 10, scale: 2
    t.decimal "released_amount", precision: 10, scale: 2
    t.index ["customer_profile_id"], name: "index_payments_on_customer_profile_id"
    t.index ["discarded_at"], name: "index_payments_on_discarded_at"
    t.index ["organization_id"], name: "index_payments_on_organization_id"
    t.index ["rental_id"], name: "index_payments_on_rental_id"
  end

  create_table "rate_rules", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "vehicle_category_id"
    t.string "name"
    t.string "season_name"
    t.date "start_date"
    t.date "end_date"
    t.decimal "daily_multiplier", precision: 8, scale: 2
    t.decimal "weekend_multiplier", precision: 8, scale: 2
    t.integer "min_rental_days", default: 1
    t.boolean "is_active", default: true
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_rate_rules_on_discarded_at"
    t.index ["organization_id"], name: "index_rate_rules_on_organization_id"
    t.index ["vehicle_category_id"], name: "index_rate_rules_on_vehicle_category_id"
  end

  create_table "rental_charges", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "rental_id"
    t.string "charge_type"
    t.string "description"
    t.decimal "unit_price", precision: 10, scale: 2
    t.decimal "quantity", precision: 10, scale: 2
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_rental_charges_on_discarded_at"
    t.index ["organization_id"], name: "index_rental_charges_on_organization_id"
    t.index ["rental_id"], name: "index_rental_charges_on_rental_id"
  end

  create_table "rentals", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "customer_profile_id"
    t.bigint "vehicle_category_id"
    t.bigint "vehicle_id"
    t.bigint "location_id"
    t.string "reservation_number"
    t.datetime "pickup_datetime"
    t.datetime "scheduled_return_datetime"
    t.datetime "actual_return_datetime"
    t.integer "scheduled_duration_days"
    t.string "status", default: "reserved"
    t.string "protection_tier", default: "basic"
    t.integer "initial_odometer"
    t.integer "final_odometer"
    t.integer "initial_fuel_percentage"
    t.integer "final_fuel_percentage"
    t.decimal "total_charges_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total_paid_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "balance_owed_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "dropoff_location_code"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "agreement_signed_at"
    t.string "agreement_signed_by_name"
    t.integer "extension_count", default: 0, null: false
    t.boolean "escalated_for_recovery", default: false, null: false
    t.datetime "last_notified_at"
    t.text "notes"
    t.index ["customer_profile_id"], name: "index_rentals_on_customer_profile_id"
    t.index ["discarded_at"], name: "index_rentals_on_discarded_at"
    t.index ["location_id"], name: "index_rentals_on_location_id"
    t.index ["organization_id"], name: "index_rentals_on_organization_id"
    t.index ["vehicle_category_id"], name: "index_rentals_on_vehicle_category_id"
    t.index ["vehicle_id"], name: "index_rentals_on_vehicle_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_roles_on_slug", unique: true
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id"
    t.bigint "role_id", null: false
    t.string "route_group"
    t.json "permissions", default: []
    t.json "granted_permissions", default: []
    t.json "denied_permissions", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "user_id, COALESCE(organization_id, (0)::bigint), role_id, COALESCE(route_group, ''::character varying)", name: "index_user_roles_on_user_org_role_group", unique: true
    t.index ["organization_id"], name: "index_user_roles_on_organization_id"
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "api_token"
    t.string "first_name"
    t.string "last_name"
    t.string "phone_number"
    t.boolean "approved", default: false, null: false
    t.datetime "email_verified_at"
    t.string "verification_token"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token"
    t.index ["verification_token"], name: "index_users_on_verification_token"
  end

  create_table "vehicle_categories", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name"
    t.string "code"
    t.text "description"
    t.decimal "base_daily_rate", precision: 10, scale: 2
    t.decimal "security_deposit_amount", precision: 10, scale: 2
    t.integer "mileage_allowance_per_day"
    t.decimal "excess_mileage_rate", precision: 10, scale: 2
    t.decimal "late_hourly_fee", precision: 10, scale: 2
    t.integer "passenger_capacity"
    t.integer "baggage_capacity"
    t.string "transmission"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_vehicle_categories_on_discarded_at"
    t.index ["organization_id"], name: "index_vehicle_categories_on_organization_id"
  end

  create_table "vehicle_maintenance_logs", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "vehicle_id"
    t.bigint "user_id"
    t.string "service_type"
    t.date "service_date"
    t.integer "odometer_at_service"
    t.decimal "cost", precision: 10, scale: 2
    t.string "vendor_name"
    t.string "status", default: "scheduled"
    t.text "notes"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_vehicle_maintenance_logs_on_discarded_at"
    t.index ["organization_id"], name: "index_vehicle_maintenance_logs_on_organization_id"
    t.index ["user_id"], name: "index_vehicle_maintenance_logs_on_user_id"
    t.index ["vehicle_id"], name: "index_vehicle_maintenance_logs_on_vehicle_id"
  end

  create_table "vehicles", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "vehicle_category_id"
    t.bigint "location_id"
    t.string "vin"
    t.string "license_plate"
    t.string "make"
    t.string "model"
    t.integer "year"
    t.string "color"
    t.integer "current_odometer", default: 0
    t.integer "fuel_percentage"
    t.string "fuel_type"
    t.string "status", default: "available"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "service_interval_miles", default: 5000, null: false
    t.integer "last_service_odometer", default: 0, null: false
    t.decimal "fuel_tank_capacity_gallons", precision: 8, scale: 2, default: "14.0", null: false
    t.date "registration_expires_on"
    t.date "acquired_on"
    t.index ["discarded_at"], name: "index_vehicles_on_discarded_at"
    t.index ["location_id"], name: "index_vehicles_on_location_id"
    t.index ["organization_id"], name: "index_vehicles_on_organization_id"
    t.index ["vehicle_category_id"], name: "index_vehicles_on_vehicle_category_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "customer_profiles", "organizations"
  add_foreign_key "customer_profiles", "users"
  add_foreign_key "damage_records", "inspections"
  add_foreign_key "damage_records", "organizations"
  add_foreign_key "damage_records", "vehicles"
  add_foreign_key "inspections", "organizations"
  add_foreign_key "inspections", "rentals"
  add_foreign_key "inspections", "users"
  add_foreign_key "inspections", "vehicles"
  add_foreign_key "locations", "organizations"
  add_foreign_key "org_role_permissions", "organizations"
  add_foreign_key "org_role_permissions", "roles"
  add_foreign_key "organization_invitations", "organizations"
  add_foreign_key "organization_invitations", "roles"
  add_foreign_key "payments", "customer_profiles"
  add_foreign_key "payments", "organizations"
  add_foreign_key "payments", "rentals"
  add_foreign_key "rate_rules", "organizations"
  add_foreign_key "rate_rules", "vehicle_categories"
  add_foreign_key "rental_charges", "organizations"
  add_foreign_key "rental_charges", "rentals"
  add_foreign_key "rentals", "customer_profiles"
  add_foreign_key "rentals", "locations"
  add_foreign_key "rentals", "organizations"
  add_foreign_key "rentals", "vehicle_categories"
  add_foreign_key "rentals", "vehicles"
  add_foreign_key "user_roles", "organizations"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "vehicle_categories", "organizations"
  add_foreign_key "vehicle_maintenance_logs", "organizations"
  add_foreign_key "vehicle_maintenance_logs", "users"
  add_foreign_key "vehicle_maintenance_logs", "vehicles"
  add_foreign_key "vehicles", "locations"
  add_foreign_key "vehicles", "organizations"
  add_foreign_key "vehicles", "vehicle_categories"
end
