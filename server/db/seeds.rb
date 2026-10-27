# frozen_string_literal: true

# ---------------------------------------------------------------------------
# DriveFlow idempotent runtime seed
#
# Single source of truth for development/test data. Re-runnable at any point
# (every lookup is find_or_initialize_by with explicit attributes) and it
# satisfies the host runtime seed contract:
#
#   * administrator@example.com / password → demo-org, full CRUD on at least
#     one tenant blueprint resource (fleet_manager role).
#   * viewer@example.com / password        → demo-org, read-only blueprint role
#     (customer role: list/show a tenant resource, cannot create it).
#   * outsider@example.com / password      → runtime-other-org ONLY. The
#     administrator must not belong to runtime-other-org.
#   * At least one valid representative record for the selected tenant resource
#     in each organization (real relationships, looked-up IDs).
#
# Role permissions are derived from server/.rhino/blueprints/*.yaml so the
# authorization chain (OrgRolePermission) matches what each blueprint declares.
# ---------------------------------------------------------------------------

require 'yaml'

SEED_PASSWORD = ENV.fetch('SEED_DEFAULT_PASSWORD', 'password')

def seed_puts(msg)
  puts "[seed] #{msg}"
end

# ---------------------------------------------------------------------------
# 1. Roles — one Role row per key in .rhino/blueprints/_roles.yaml
# ---------------------------------------------------------------------------
blueprint_dir = Rails.root.join('.rhino', 'blueprints')
roles_spec = YAML.load_file(blueprint_dir.join('_roles.yaml'))['roles'] || {}

roles = {}
roles_spec.each do |slug, spec|
  role = Role.find_or_initialize_by(slug: slug)
  role.name = spec['name'].presence || slug.titleize
  role.description = spec['description'] if spec['description'].present?
  role.save!
  roles[slug] = role
end
seed_puts "roles: #{roles.keys.join(', ')}"

# The host runtime contract uses a read-only blueprint role for viewer@.
# `customer` is read-only on the tenant resources (index/show only).
read_only_role = roles['customer']

# ---------------------------------------------------------------------------
# 2. Organizations
# ---------------------------------------------------------------------------
demo_org = Organization.find_or_initialize_by(slug: 'demo-org')
demo_org.name = 'DriveFlow Demo Rentals'
demo_org.description = 'Primary demo organization (host runtime smoke target).'
demo_org.save!

other_org = Organization.find_or_initialize_by(slug: 'runtime-other-org')
other_org.name = 'Runtime Other Rentals'
other_org.description = 'Isolation organization — holds no DriveFlow demo identities.'
other_org.save!

seed_puts "organizations: #{demo_org.slug}, #{other_org.slug}"

# ---------------------------------------------------------------------------
# 3. OrgRolePermission — the role layer, derived from the blueprints
#
# blueprint permissions declare actions: [index, show, store, update, ...];
# Rhino's permission strings are "#{model_slug}.#{action}".
# ---------------------------------------------------------------------------
blueprint_files = Dir.glob(blueprint_dir.join('*.yaml').to_s)
                     .reject { |p| File.basename(p) == '_roles.yaml' }

role_permissions = Hash.new { |h, k| h[k] = [] }

blueprint_files.each do |path|
  spec = YAML.load_file(path)
  slug = spec['slug'] || spec['model'].to_s.underscore.pluralize
  perms = spec['permissions'] || {}
  perms.each do |role_slug, config|
    actions = Array(config['actions'])
    next if actions.empty?

    role_permissions[role_slug].concat(actions.map { |a| "#{slug}.#{a}" })
  end
end

# Non-CRUD custom endpoints (services backed by controllers). The role sets
# mirror the access tiers: counter staff own the counter, inspection and
# settlement surfaces; fleet managers own admin analytics, billing recovery
# and fleet scheduling.
role_permissions['counter_agent'] += %w[
  counter.departures counter.returns counter.lookup
  payments.hold payments.capture payments.release payments.settle
  agreements.show agreements.sign agreements.complete_handover
  inspections.photos inspections.finish
  documents.store
  rentals.receipt rentals.settlement_preview rentals.inspection_comparison
  receipts.index receipts.show
]
role_permissions['fleet_manager'] += %w[
  counter.departures counter.returns counter.lookup
  payments.hold payments.expand_hold payments.capture payments.release
  payments.settle payments.charge_balance payments.refund
  agreements.show agreements.sign agreements.complete_handover
  inspections.photos inspections.finish
  documents.store
  fleet_matrix.index
  analytics.show analytics.export
  billing.outstanding
  rentals.receipt rentals.settlement_preview rentals.inspection_comparison
  rentals.notify rentals.notes rentals.escalate rentals.extend
  receipts.index receipts.show
]
role_permissions['customer'] += %w[receipts.index receipts.show]
# Read-only organization + role metadata is needed by every authenticated
# surface: the client resolves the caller's roles from /roles (and the sidebar /
# role gates read that), and the shell shows the organization name. These are
# read-only listings — no role gains a write.
%w[fleet_manager counter_agent customer].each do |role_slug|
  role_permissions[role_slug] += %w[organizations.index organizations.show roles.index roles.show]
end
# The viewer identity (read-only contract role) stays strictly list/show.
role_permissions['customer'] = (role_permissions['customer'] +
  %w[rentals.index rentals.show payments.index payments.show
     customer_profiles.index customer_profiles.show]).uniq

role_permissions.each do |role_slug, permissions|
  role = roles[role_slug]
  next unless role

  [demo_org, other_org].each do |org|
    record = OrgRolePermission.find_or_initialize_by(organization: org, role: role)
    record.permissions = permissions.uniq.sort
    record.save!
  end
end
seed_puts "org role permissions: #{role_permissions.transform_values(&:size).inspect}"

# ---------------------------------------------------------------------------
# 4. Runtime identities (host smoke contract)
# ---------------------------------------------------------------------------
def upsert_user(email:, name:, first_name:, last_name:, phone:, password:)
  user = User.find_or_initialize_by(email: email)
  user.name = name
  user.first_name = first_name
  user.last_name = last_name
  user.phone_number = phone
  user.approved = true
  user.email_verified_at ||= Time.current
  # Only set the password when the stored digest is missing so re-running seeds
  # repairs an older user without clobbering a rotated credential.
  if user.new_record? || user.password_digest.blank?
    user.password = password
    user.password_confirmation = password
  end
  user.save!
  user
end

administrator = upsert_user(
  email: 'administrator@example.com', name: 'Ada Administrator',
  first_name: 'Ada', last_name: 'Administrator',
  phone: '+1-415-555-0100', password: SEED_PASSWORD
)

# The read-only runtime identity is also a `customer`, and customer_profiles is
# row-scoped to the caller's own profile — so this identity owns a profile of its
# own (seeded below). Its full name sorts first among the demo-org profiles,
# which is the order the tenant list uses, so the record the runtime contract
# reads as the full-access role is the same one the limited role can list.
viewer = upsert_user(
  email: 'viewer@example.com', name: 'Avery Viewer',
  first_name: 'Avery', last_name: 'Viewer',
  phone: '+1-415-555-0101', password: SEED_PASSWORD
)

outsider = upsert_user(
  email: 'outsider@example.com', name: 'Otis Outsider',
  first_name: 'Otis', last_name: 'Outsider',
  phone: '+1-415-555-0102', password: SEED_PASSWORD
)

# Additional demo identities kept for the PRD personas.
fleet_manager_user = upsert_user(
  email: 'fleet_manager@demo.com', name: 'Elena Rostova',
  first_name: 'Elena', last_name: 'Rostova',
  phone: '+1-415-555-0110', password: SEED_PASSWORD
)

counter_agent_user = upsert_user(
  email: 'counter_agent@demo.com', name: 'Marcus Vance',
  first_name: 'Marcus', last_name: 'Vance',
  phone: '+1-415-555-0111', password: SEED_PASSWORD
)

customer_user = upsert_user(
  email: 'customer@demo.com', name: 'David Chen',
  first_name: 'David', last_name: 'Chen',
  phone: '+1-415-555-0112', password: SEED_PASSWORD
)

# ---------------------------------------------------------------------------
# 5. Memberships (UserRole)
# ---------------------------------------------------------------------------
def upsert_user_role(user:, organization:, role:)
  membership = UserRole.find_or_initialize_by(user: user, organization: organization, role: role)
  membership.route_group = nil
  membership.permissions = [] if membership.permissions.blank?
  membership.save!
  membership
end

upsert_user_role(user: administrator, organization: demo_org, role: roles['fleet_manager'])
upsert_user_role(user: viewer, organization: demo_org, role: read_only_role)
upsert_user_role(user: outsider, organization: other_org, role: read_only_role)

upsert_user_role(user: fleet_manager_user, organization: demo_org, role: roles['fleet_manager'])
upsert_user_role(user: counter_agent_user, organization: demo_org, role: roles['counter_agent'])
upsert_user_role(user: customer_user, organization: demo_org, role: roles['customer'])

seed_puts 'memberships: administrator(fleet_manager/demo-org), viewer(customer/demo-org), outsider(customer/runtime-other-org)'

# ---------------------------------------------------------------------------
# 6. Representative tenant records — one full graph per organization
#
# The tenant resource the host validates is `vehicle_categories` (readable by
# every blueprint role) with its real relationships (locations, vehicles,
# rate rules, customer profile, rental, inspection, charge, payment).
# ---------------------------------------------------------------------------
def seed_organization_records(org:, suffix:, customer_user: nil, counter_user: nil, manager_user: nil)
  location = Location.find_or_initialize_by(organization: org, code: "SFO-01-#{suffix}")
  location.assign_attributes(
    name: 'San Francisco International Airport Branch',
    address: '780 North Access Rd, Terminal 2',
    city: 'San Francisco', state: 'CA', postal_code: '94128',
    phone: '+1-650-555-0144', email: "sfo-#{suffix}@driveflow.com", is_active: true
  )
  location.save!

  downtown = Location.find_or_initialize_by(organization: org, code: "SF-DWTN-#{suffix}")
  downtown.assign_attributes(
    name: 'Downtown San Francisco Financial District',
    address: '500 Market Street',
    city: 'San Francisco', state: 'CA', postal_code: '94105',
    phone: '+1-415-555-0160', email: "downtown-#{suffix}@driveflow.com", is_active: true
  )
  downtown.save!

  category = VehicleCategory.find_or_initialize_by(organization: org, code: "PCAR-#{suffix}")
  category.assign_attributes(
    name: 'Premium Electric Sedan',
    description: 'Premium long-range electric sedan with autopilot navigation and supercharging.',
    base_daily_rate: 115.00, security_deposit_amount: 500.00,
    mileage_allowance_per_day: 250, excess_mileage_rate: 0.45, late_hourly_fee: 35.00,
    passenger_capacity: 5, baggage_capacity: 2, transmission: 'automatic'
  )
  category.save!

  suv = VehicleCategory.find_or_initialize_by(organization: org, code: "CFAR-#{suffix}")
  suv.assign_attributes(
    name: 'Compact SUV',
    description: 'Compact AWD SUV with versatile cargo space and 34 MPG efficiency.',
    base_daily_rate: 68.50, security_deposit_amount: 300.00,
    mileage_allowance_per_day: 200, excess_mileage_rate: 0.35, late_hourly_fee: 25.00,
    passenger_capacity: 5, baggage_capacity: 3, transmission: 'automatic'
  )
  suv.save!

  vehicle = Vehicle.find_or_initialize_by(organization: org, vin: "5YJ3E1EB5NF20481#{suffix}")
  vehicle.assign_attributes(
    vehicle_category: category, location: location,
    license_plate: "9TSL#{suffix}",
    make: 'Tesla', model: 'Model 3 Long Range', year: 2023,
    color: 'Pearl White Multi-Coat',
    current_odometer: 18_420, last_service_odometer: 15_000, service_interval_miles: 5000,
    fuel_percentage: 92, fuel_type: 'electric', fuel_tank_capacity_gallons: 14.0,
    status: 'available'
  )
  vehicle.save!

  suv_vehicle = Vehicle.find_or_initialize_by(organization: org, vin: "2T3C1RFV2NW08910#{suffix}")
  suv_vehicle.assign_attributes(
    vehicle_category: suv, location: location,
    license_plate: "8TRV#{suffix}",
    make: 'Toyota', model: 'RAV4 XLE', year: 2023,
    color: 'Magnetic Gray Metallic',
    current_odometer: 24_150, last_service_odometer: 24_000, service_interval_miles: 5000,
    fuel_percentage: 100, fuel_type: 'gasoline', fuel_tank_capacity_gallons: 14.5,
    status: 'available'
  )
  suv_vehicle.save!

  rate_rule = RateRule.find_or_initialize_by(organization: org, vehicle_category: category,
                                             name: 'Standard Year-Round Rate')
  rate_rule.assign_attributes(
    season_name: 'regular', start_date: Date.new(2025, 1, 1), end_date: Date.new(2027, 12, 31),
    daily_multiplier: 1.0, weekend_multiplier: 1.15, min_rental_days: 1, is_active: true
  )
  rate_rule.save!

  # Refueling fee schedule ($8.00/gal default) + late return hourly fee.
  refuel_rule = RateRule.find_or_initialize_by(organization: org, vehicle_category: category,
                                               name: 'Premium Refueling Rate')
  refuel_rule.assign_attributes(
    season_name: 'refueling_rate', start_date: Date.new(2025, 1, 1), end_date: Date.new(2027, 12, 31),
    daily_multiplier: 8.0, weekend_multiplier: 1.0, min_rental_days: 1, is_active: true
  )
  refuel_rule.save!

  late_rule = RateRule.find_or_initialize_by(organization: org, vehicle_category: category,
                                             name: 'Late Return Hourly Fee')
  late_rule.assign_attributes(
    season_name: 'late_return_fee', start_date: Date.new(2025, 1, 1), end_date: Date.new(2027, 12, 31),
    daily_multiplier: 35.0, weekend_multiplier: 1.0, min_rental_days: 1, is_active: true
  )
  late_rule.save!

  profile = CustomerProfile.find_or_initialize_by(organization: org, email: "david.chen+#{suffix}@example.com")
  profile.assign_attributes(
    user: customer_user, full_name: 'David Chen',
    license_number: "CA-D88291#{suffix}", license_state: 'CA',
    license_expiry_date: Date.new(2027, 8, 31), license_country: 'USA', license_verified: true,
    stripe_customer_token: "cus_demo_#{suffix}", phone_number: '+1-415-555-0192',
    date_of_birth: Date.new(1988, 6, 14),
    address: '742 Evergreen Terrace, San Francisco, CA 94107',
    card_last4: '4242', card_brand: 'visa'
  )
  profile.save!

  rental = Rental.find_or_initialize_by(organization: org, reservation_number: "DF-2025-#{suffix}831")
  rental.assign_attributes(
    customer_profile: profile, vehicle_category: category, vehicle: vehicle, location: location,
    pickup_datetime: 5.days.ago.change(hour: 9, min: 0, sec: 0),
    scheduled_return_datetime: 1.day.ago.change(hour: 9, min: 0, sec: 0),
    actual_return_datetime: 1.day.ago.change(hour: 9, min: 30, sec: 0),
    scheduled_duration_days: 4, status: 'completed', protection_tier: 'standard',
    initial_odometer: 18_120, final_odometer: 18_420,
    initial_fuel_percentage: 100, final_fuel_percentage: 92,
    dropoff_location_code: location.code,
    agreement_signed_at: 5.days.ago, agreement_signed_by_name: 'David Chen'
  )
  rental.save!

  base_charge = RentalCharge.find_or_initialize_by(organization: org, rental: rental, charge_type: 'base_rate')
  base_charge.assign_attributes(
    description: 'Premium Electric Sedan 4-day base rental ($115/day)',
    unit_price: 115.00, quantity: 4, amount: 460.00
  )
  base_charge.save!

  protection_charge = RentalCharge.find_or_initialize_by(organization: org, rental: rental,
                                                         charge_type: 'insurance_protection')
  protection_charge.assign_attributes(
    description: 'Collision Damage Waiver (Standard) $25/day',
    unit_price: 25.00, quantity: 4, amount: 100.00
  )
  protection_charge.save!

  tax_charge = RentalCharge.find_or_initialize_by(organization: org, rental: rental, charge_type: 'sales_tax')
  tax_charge.assign_attributes(
    description: 'State and municipal vehicle rental tax (6.5%)',
    unit_price: 36.40, quantity: 1, amount: 36.40
  )
  tax_charge.save!

  payment = Payment.find_or_initialize_by(organization: org, rental: rental,
                                          transaction_type: 'rental_payment',
                                          stripe_payment_intent_key: "pi_seed_#{suffix}_rental")
  payment.assign_attributes(
    customer_profile: profile, stripe_charge_key: "ch_seed_#{suffix}",
    amount: 596.40, status: 'succeeded', payment_method_last4: '4242',
    processed_at: 5.days.ago,
    notes: 'Online booking pre-payment covering base rate, protection and taxes.'
  )
  payment.save!

  hold = Payment.find_or_initialize_by(organization: org, rental: rental,
                                       transaction_type: 'deposit_hold',
                                       stripe_payment_intent_key: "pi_seed_#{suffix}_hold")
  hold.assign_attributes(
    customer_profile: profile, amount: 500.00, status: 'succeeded',
    payment_method_last4: '4242', processed_at: 5.days.ago,
    notes: 'Counter pickup security deposit pre-authorization hold.'
  )
  hold.save!

  rental.recalculate_totals!

  inspection = Inspection.find_or_initialize_by(organization: org, rental: rental, inspection_type: 'check_out')
  inspection.assign_attributes(
    vehicle: vehicle, user: counter_user,
    odometer_reading: 18_120, fuel_percentage: 100, cleanliness_status: 'clean',
    customer_signature_url: "https://storage.driveflow.com/signatures/#{rental.reservation_number}-checkout.png",
    customer_signature_timestamp: 5.days.ago, status: 'completed',
    notes: 'Departure walkaround complete. Four quadrant photos captured.',
    performed_at: 5.days.ago
  )
  inspection.save!

  return_inspection = Inspection.find_or_initialize_by(organization: org, rental: rental,
                                                       inspection_type: 'check_in')
  return_inspection.assign_attributes(
    vehicle: vehicle, user: counter_user,
    odometer_reading: 18_420, fuel_percentage: 92, cleanliness_status: 'moderate',
    status: 'completed', notes: 'Return walkaround complete. No new damage.',
    performed_at: 1.day.ago
  )
  return_inspection.save!

  damage = DamageRecord.find_or_initialize_by(organization: org, inspection: inspection,
                                              panel_location: 'rear_bumper', severity: 'minor_scratch')
  damage.assign_attributes(
    vehicle: vehicle,
    description: '3-inch light surface clearcoat scuff near trunk latch. No paint penetration.',
    photo_url: "https://storage.driveflow.com/damage/#{suffix}-rear-scuff.jpg",
    is_pre_existing: true, repair_cost_estimate: 0, repaired: false,
    photo_taken_at: 5.days.ago, captured_angle: 'rear'
  )
  damage.save!

  maintenance = VehicleMaintenanceLog.find_or_initialize_by(organization: org, vehicle: suv_vehicle,
                                                            service_date: Date.new(2025, 3, 15))
  maintenance.assign_attributes(
    user: manager_user, service_type: 'oil_change', odometer_at_service: 20_100,
    cost: 185.00, vendor_name: 'Bay City Fleet Care', status: 'completed',
    notes: 'Synthetic 0W-20 oil and OEM filter replacement.'
  )
  maintenance.save!

  # --- Operational states the queues and admin screens need -----------------
  # A vehicle whose odometer is inside the service window (AC-70: Service Due).
  due_vehicle = Vehicle.find_or_initialize_by(organization: org, vin: "3VW2K7AJ9EM3#{suffix}8421")
  due_vehicle.assign_attributes(
    vehicle_category: suv, location: location,
    license_plate: "8SRV#{suffix}",
    make: 'Volkswagen', model: 'Jetta SE', year: 2022,
    color: 'Deep Black Pearl',
    current_odometer: 40_240, last_service_odometer: 35_000, service_interval_miles: 5000,
    fuel_percentage: 62, fuel_type: 'gasoline', fuel_tank_capacity_gallons: 13.2,
    status: 'available'
  )
  due_vehicle.save!

  # Upcoming reservation → Counter departures queue (AC-28).
  upcoming = Rental.find_or_initialize_by(organization: org, reservation_number: "DF-UP-#{suffix}")
  upcoming.assign_attributes(
    customer_profile: profile, vehicle_category: category, vehicle: vehicle, location: location,
    pickup_datetime: 1.day.from_now.change(hour: 10, min: 0, sec: 0),
    scheduled_return_datetime: 4.days.from_now.change(hour: 10, min: 0, sec: 0),
    scheduled_duration_days: 3, status: 'confirmed', protection_tier: 'full',
    dropoff_location_code: location.code
  )
  upcoming.save!
  BookingChargeService.new(upcoming).persist!
  # The online reservation is prepaid, so it must not appear in the accounts
  # receivable list — only genuinely delinquent contracts do.
  prepaid = Payment.find_or_initialize_by(organization: org, rental: upcoming,
                                         transaction_type: 'rental_payment',
                                         stripe_payment_intent_key: "pi_seed_#{suffix}_upcoming")
  prepaid.assign_attributes(
    customer_profile: profile, stripe_charge_key: "ch_seed_#{suffix}_up",
    amount: upcoming.rental_charges.kept.sum(:amount).to_d, status: 'succeeded',
    payment_method_last4: '4242', processed_at: Time.current,
    notes: 'Online booking pre-payment covering base rate, protection and taxes.'
  )
  prepaid.save!
  upcoming.recalculate_totals!

  # On-rent contract → Counter returns queue / Active rentals (AC-81, AC-90).
  active = Rental.find_or_initialize_by(organization: org, reservation_number: "DF-ACT-#{suffix}")
  active.assign_attributes(
    customer_profile: profile, vehicle_category: suv, vehicle: suv_vehicle, location: location,
    pickup_datetime: 2.days.ago.change(hour: 8, min: 0, sec: 0),
    scheduled_return_datetime: 1.day.from_now.change(hour: 18, min: 0, sec: 0),
    scheduled_duration_days: 3, status: 'active', protection_tier: 'standard',
    initial_odometer: 23_900, initial_fuel_percentage: 100,
    dropoff_location_code: location.code,
    agreement_signed_at: 2.days.ago, agreement_signed_by_name: 'David Chen'
  )
  active.save!
  active_hold = Payment.find_or_initialize_by(organization: org, rental: active,
                                              transaction_type: 'deposit_hold',
                                              stripe_payment_intent_key: "pi_seed_#{suffix}_active_hold")
  active_hold.assign_attributes(
    customer_profile: profile, amount: suv.security_deposit_amount, status: 'succeeded',
    payment_method_last4: '4242', processed_at: 2.days.ago,
    notes: 'Counter pickup security deposit pre-authorization hold.'
  )
  active_hold.save!

  # Overdue contract past the 60-minute grace (AC-82, AC-85, AC-65) with an
  # outstanding balance so billing/outstanding has a row.
  overdue = Rental.find_or_initialize_by(organization: org, reservation_number: "DF-OVD-#{suffix}")
  overdue.assign_attributes(
    customer_profile: profile, vehicle_category: suv, vehicle: due_vehicle, location: location,
    pickup_datetime: 4.days.ago.change(hour: 9, min: 0, sec: 0),
    scheduled_return_datetime: 3.hours.ago.change(min: 0, sec: 0),
    scheduled_duration_days: 2, status: 'overdue', protection_tier: 'basic',
    initial_odometer: 39_800, initial_fuel_percentage: 100,
    total_charges_amount: 137.00, total_paid_amount: 137.00, balance_owed_amount: 240.00,
    dropoff_location_code: location.code,
    notes: 'Flagged by the overdue sweeper — no authorized extension on file.'
  )
  overdue.save!
  overdue_charge = RentalCharge.find_or_initialize_by(organization: org, rental: overdue, charge_type: 'base_rate')
  overdue_charge.assign_attributes(
    description: 'Compact SUV 2-day base rental ($68.50/day)', unit_price: 68.50, quantity: 2, amount: 137.00
  )
  overdue_charge.save!
  overdue_hold = Payment.find_or_initialize_by(organization: org, rental: overdue,
                                               transaction_type: 'deposit_hold',
                                               stripe_payment_intent_key: "pi_seed_#{suffix}_overdue_hold")
  overdue_hold.assign_attributes(
    customer_profile: profile, amount: suv.security_deposit_amount, status: 'succeeded',
    payment_method_last4: '4242', processed_at: 4.days.ago,
    notes: 'Counter pickup security deposit pre-authorization hold.'
  )
  overdue_hold.save!

  { location: location, category: category, vehicle: vehicle, rental: rental, profile: profile,
    overdue: overdue, active: active, upcoming: upcoming }
end

demo_records = seed_organization_records(
  org: demo_org, suffix: '01',
  customer_user: customer_user, counter_user: counter_agent_user, manager_user: fleet_manager_user
)
other_records = seed_organization_records(org: other_org, suffix: '02')

seed_puts "representative records: demo-org category=#{demo_records[:category].code}, " \
          "runtime-other-org category=#{other_records[:category].code}"

# Each read-only runtime identity owns a customer profile plus a
# rental → inspection → damage graph. The row-scoped resources a `customer` may
# list (damage_records, inspections, rentals, payments) resolve through the
# caller's own profile, so an identity with no profile would list nothing. The
# demo-org graph is seeded last so its damage record is also the newest — the
# record the full-access role reads first when it lists the tenant resource.
def seed_read_only_graph(user:, org:, records:, counter_user:, suffix:, viewer:, address:)
  profile = CustomerProfile.find_or_initialize_by(organization: org, user: user)
  profile.assign_attributes(
    full_name: user.display_name,
    email: user.email,
    phone_number: user.phone_number,
    address: address,
    date_of_birth: Date.new(1990, 1, 15),
    license_number: "CA-V100#{suffix}", license_state: 'CA',
    license_expiry_date: Date.new(2029, 1, 15), license_country: 'USA',
    license_verified: true
  )
  profile.save!

  rental = Rental.find_or_initialize_by(organization: org, reservation_number: "DF-#{viewer}-#{suffix}")
  rental.assign_attributes(
    customer_profile: profile, vehicle_category: records[:category],
    vehicle: records[:vehicle], location: records[:location],
    pickup_datetime: 10.days.ago.change(hour: 10, min: 0, sec: 0),
    scheduled_return_datetime: 7.days.ago.change(hour: 10, min: 0, sec: 0),
    actual_return_datetime: 7.days.ago.change(hour: 10, min: 20, sec: 0),
    scheduled_duration_days: 3, status: 'completed', protection_tier: 'basic',
    initial_odometer: 18_180, final_odometer: 18_420,
    initial_fuel_percentage: 100, final_fuel_percentage: 96,
    dropoff_location_code: records[:location].code
  )
  rental.save!

  inspection = Inspection.find_or_initialize_by(
    organization: org, rental: rental, inspection_type: 'check_in'
  )
  inspection.assign_attributes(
    vehicle: records[:vehicle], user: counter_user,
    odometer_reading: 18_420, fuel_percentage: 96, cleanliness_status: 'clean',
    performed_at: 7.days.ago.change(hour: 10, min: 22, sec: 0)
  )
  inspection.save!

  damage = DamageRecord.find_or_initialize_by(
    organization: org, inspection: inspection, panel_location: 'passenger_rear_door'
  )
  damage.assign_attributes(
    vehicle: records[:vehicle], severity: 'minor_scratch', is_pre_existing: false,
    description: 'Light surface scuff recorded for the read-only demo identity.',
    photo_url: "https://storage.driveflow.com/damage/#{suffix}-viewer-scuff.jpg",
    repaired: false, repair_cost_estimate: 0
  )
  damage.save!

  profile
end

viewer_profile = seed_read_only_graph(
  user: viewer, org: demo_org, records: demo_records, counter_user: counter_agent_user,
  suffix: '01', viewer: 'VIEW', address: '1 Viewer Way, San Francisco, CA 94105'
)
seed_puts "read-only graph: #{viewer.email} → #{viewer_profile.full_name} (#{viewer_profile.organization.slug})"

# The other organization holds only its own read-only identity's graph — never a
# demo-org record (the runtime contract asserts the two lists do not overlap).
outsider_profile = seed_read_only_graph(
  user: outsider, org: other_org, records: other_records, counter_user: nil,
  suffix: '02', viewer: 'OTIS', address: '9 Outsider Lane, Reno, NV 89501'
)
seed_puts "read-only graph: #{outsider.email} → #{outsider_profile.full_name} (#{outsider_profile.organization.slug})"

# ---------------------------------------------------------------------------
# 7. Contract verification — fail loudly if the contract is broken
# ---------------------------------------------------------------------------
{
  'administrator@example.com' => demo_org,
  'viewer@example.com' => demo_org,
  'outsider@example.com' => other_org
}.each do |email, org|
  user = User.find_by(email: email)
  resolved = user&.organizations&.map(&:slug)
  seed_puts "#{email} → orgs=#{resolved.inspect}"
end

admin = User.find_by(email: 'administrator@example.com')
raise '[seed] FAILED: administrator@example.com missing' if admin.nil?
raise '[seed] FAILED: administrator is default-deny on demo-org' unless admin.has_permission?('vehicle_categories.index', demo_org)
raise '[seed] FAILED: administrator unexpectedly belongs to runtime-other-org' if admin.organizations.include?(other_org)

viewer_user = User.find_by(email: 'viewer@example.com')
if viewer_user.nil? || !viewer_user.has_permission?('vehicle_categories.index', demo_org) ||
   viewer_user.has_permission?('vehicle_categories.store', demo_org)
  raise '[seed] FAILED: viewer@example.com is not read-only on demo-org'
end

if outsider.nil? || !outsider.has_permission?('vehicle_categories.index', other_org) ||
   outsider.has_permission?('vehicle_categories.index', demo_org)
  raise '[seed] FAILED: outsider@example.com isolation broken'
end

viewer_user = User.find_by(email: 'viewer@example.com')
newest_damage = DamageRecord.where(organization_id: demo_org.id).order(created_at: :desc).first
unless newest_damage && newest_damage.inspection&.rental&.customer_profile_id == viewer_profile.id
  raise '[seed] FAILED: the newest damage record is not the read-only identity\'s own record'
end

seed_puts 'done'
