ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module DriveFlowTestHelpers
  # ---------------------------------------------------------------
  # Tenant fixtures
  # ---------------------------------------------------------------

  def create_organization(slug: "demo-org", name: nil)
    Organization.find_or_create_by!(slug: slug) { |o| o.name = name || slug.titleize }
  end

  def create_role(slug:)
    Role.find_or_create_by!(slug: slug) { |r| r.name = slug.titleize }
  end

  # Role-layer permissions (the layer Rhino resolves for tenant requests).
  def grant(organization, role, *permissions)
    record = OrgRolePermission.find_or_initialize_by(organization: organization, role: role)
    record.permissions = (Array(record.permissions) + permissions.flatten).uniq.sort
    record.save!
    record
  end

  def create_user(email:, password: "password", name: nil, approved: true)
    user = User.find_or_initialize_by(email: email)
    user.name = name || email.split("@").first.titleize
    user.password = password
    user.password_confirmation = password
    user.approved = approved
    user.save!
    user
  end

  def member_of(organization, role_slug:, email: nil, role: nil)
    role ||= create_role(slug: role_slug)
    user = create_user(email: email || "#{role_slug}-#{SecureRandom.hex(3)}@example.com")
    UserRole.find_or_create_by!(user: user, organization: organization, role: role)
    user
  end

  def auth_headers(user)
    user.regenerate_api_token
    { "Authorization" => "Bearer #{user.api_token}" }
  end

  # Grants a role the full CRUD set for the given slugs.
  def crud!(organization, role, *slugs, actions: %w[index show store update destroy])
    slugs.each { |slug| grant(organization, role, actions.map { |a| "#{slug}.#{a}" }) }
  end

  # ---------------------------------------------------------------
  # Request-context helpers (for model/service tests outside a request)
  # ---------------------------------------------------------------

  def rhino_context(user:, organization:)
    Rhino.for_user(user).in_organization(organization)
  end

  def with_context(user:, organization:, &block)
    rhino_context(user: user, organization: organization).run(&block)
  end

  # ---------------------------------------------------------------
  # A complete seeded-ish rental graph for service/controller tests
  # ---------------------------------------------------------------

  def build_rental_graph(organization:, suffix: SecureRandom.hex(3), **overrides)
    location = Location.create!(
      organization: organization, name: "Test Branch #{suffix}", code: "T-#{suffix}",
      city: "San Francisco", state: "CA", postal_code: "94105", is_active: true
    )
    category = VehicleCategory.create!(
      organization: organization, name: "Test SUV #{suffix}", code: "TS-#{suffix}",
      base_daily_rate: 100, security_deposit_amount: 300, mileage_allowance_per_day: 200,
      excess_mileage_rate: 0.35, late_hourly_fee: 35, passenger_capacity: 5,
      baggage_capacity: 3, transmission: "automatic"
    )
    vehicle = Vehicle.create!(
      organization: organization, vehicle_category: category, location: location,
      vin: "VIN#{SecureRandom.hex(6)}", license_plate: "PL#{suffix}", make: "Toyota",
      model: "RAV4", year: 2023, color: "Gray", current_odometer: 10_000,
      last_service_odometer: 9_000, service_interval_miles: 5_000,
      fuel_percentage: 100, fuel_type: "gasoline", fuel_tank_capacity_gallons: 14,
      status: "available"
    )
    profile = CustomerProfile.create!(
      organization: organization, full_name: "Renter #{suffix}", email: "renter-#{suffix}@example.com",
      license_number: "CA-#{suffix}", license_state: "CA", license_country: "USA",
      license_verified: true, license_expiry_date: 2.years.from_now.to_date,
      card_last4: "4242", card_brand: "visa"
    )
    rental = Rental.create!(
      organization: organization, customer_profile: profile, vehicle_category: category,
      vehicle: vehicle, location: location, reservation_number: "DF-T-#{suffix}",
      pickup_datetime: 3.days.ago.change(hour: 9), scheduled_return_datetime: 1.day.ago.change(hour: 9),
      scheduled_duration_days: 2, status: "active", protection_tier: "standard",
      initial_odometer: 9_800, initial_fuel_percentage: 100,
      dropoff_location_code: location.code, **overrides
    )
    { organization: organization, location: location, category: category, vehicle: vehicle,
      profile: profile, rental: rental }
  end
end

module ActiveSupport
  class TestCase
    # A shared test database serialised across workers keeps the per-role
    # authorization matrix deterministic.
    parallelize(workers: 1)

    # Add more helper methods to be used by all tests here...
    include DriveFlowTestHelpers
  end
end

