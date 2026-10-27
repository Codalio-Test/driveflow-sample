# frozen_string_literal: true

require "test_helper"

# AC-8 / AC-39 / AC-62 / AC-64 / AC-116 / AC-124 — the Vehicle data model.
class VehicleTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "vehicle-org")
    @graph = build_rental_graph(organization: @org)
    @vehicle = @graph[:vehicle]
  end

  test "colour is persisted (AC-8)" do
    assert_equal "Gray", @vehicle.color
    assert @vehicle.valid?
  end

  test "fuel type is persisted (AC-39)" do
    assert_equal "gasoline", @vehicle.fuel_type
  end

  test "status vocabulary is the normalized enum (AC-124)" do
    assert_equal %w[available reserved rented maintenance cleaning overdue], Vehicle::STATUSES
    Vehicle::STATUSES.each do |status|
      @vehicle.status = status
      assert @vehicle.valid?, "status #{status} should be valid"
    end
    @vehicle.status = "detailing"
    assert_not @vehicle.valid?
    assert_includes @vehicle.errors[:status], "is not included in the list"
  end

  test "vin and license plate are required and unique per organization" do
    duplicate = Vehicle.new(
      organization: @org, vehicle_category: @graph[:category], location: @graph[:location],
      vin: @vehicle.vin, license_plate: "OTHER-1", make: "Ford", model: "Focus",
      year: 2022, current_odometer: 10, status: "available"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:vin], "has already been taken"
  end

  test "same vin may exist in a different organization" do
    other = create_organization(slug: "vehicle-other-org")
    category = VehicleCategory.create!(organization: other, name: "C", code: "C1",
                                       base_daily_rate: 10, security_deposit_amount: 10)
    location = Location.create!(organization: other, name: "L", code: "L1", is_active: true)
    twin = Vehicle.create!(organization: other, vehicle_category: category, location: location,
                           vin: @vehicle.vin, license_plate: "TWN-1", make: "Toyota",
                           model: "RAV4", year: 2023, current_odometer: 0, status: "available")
    assert twin.persisted?
  end

  test "fuel percentage is bounded 0..100" do
    @vehicle.fuel_percentage = 140
    assert_not @vehicle.valid?
  end

  test "onboarding requires vin, plate, make, model, year, category and odometer (AC-61)" do
    blank = Vehicle.new(organization: @org, current_odometer: nil)
    assert_not blank.valid?
    %i[vin license_plate make model year current_odometer].each do |field|
      assert_includes blank.errors.attribute_names, field, "expected #{field} to be required"
    end
  end

  test "service_due and next_service_odometer are computed (AC-70 / AC-116)" do
    @vehicle.update!(current_odometer: 13_800)
    assert_equal 14_000, @vehicle.next_service_odometer
    assert_equal 200, @vehicle.miles_until_service
    assert @vehicle.service_due?

    @vehicle.update!(current_odometer: 10_000)
    assert_not @vehicle.service_due?
    assert_equal 4_000, @vehicle.miles_until_service
  end

  test "health percentage tracks consumed service life" do
    @vehicle.update!(current_odometer: 11_500)
    assert_in_delta 50.0, @vehicle.service_progress, 0.1
    assert_in_delta 50.0, @vehicle.health_percentage, 0.1
  end

  test "ServiceDue scope selects vehicles inside the service window (AC-116)" do
    @vehicle.update!(current_odometer: 13_900)
    matched = Scopes::VehicleServiceDueScope.new.apply(Vehicle.unscoped).pluck(:id)
    assert_includes matched, @vehicle.id

    @vehicle.update!(current_odometer: 9_500)
    not_due = Scopes::VehicleServiceDueScope.new.apply(Vehicle.unscoped).pluck(:id)
    assert_not_includes not_due, @vehicle.id
  end

  test "an active work order forces maintenance status (AC-72)" do
    log = VehicleMaintenanceLog.create!(
      organization: @org, vehicle: @vehicle, service_type: "oil_change",
      service_date: Date.current, status: "in_progress"
    )
    assert_equal "maintenance", @vehicle.reload.status
    assert @vehicle.active_maintenance?
    assert_not @vehicle.available_for_rental?

    log.update!(status: "completed")
    assert_equal "available", @vehicle.reload.status
    assert_not @vehicle.active_maintenance?
  end

  test "computed attributes feed the prototype display contract (AC-15)" do
    attrs = @vehicle.rhino_computed_attributes
    assert_equal "2023 Toyota RAV4", attrs["name"]
    assert_equal @vehicle.license_plate, attrs["plate"]
    assert_equal @graph[:location].name, attrs["location"]
    assert_equal "10000 mi", attrs["miles"]
    assert attrs.key?("health")
  end
end
