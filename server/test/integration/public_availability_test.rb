# frozen_string_literal: true

require "test_helper"

# AC-1 / AC-112 — the public availability search, including the conditional
# "bookable" rule the blueprint cannot express:
#
#   a vehicle is bookable only when status == 'available' AND it has no
#   overlapping Rental in reserved|confirmed|active|overdue
#
# and the maintenance gate (an active work order forces Vehicle#status to
# 'maintenance', which removes the car from online availability).
class PublicAvailabilityTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization(slug: "availability-org")
    @other_org = create_organization(slug: "availability-other-org")
    @graph = build_rental_graph(organization: @org)
    @category = @graph[:category]
    @vehicle = @graph[:vehicle]
  end

  def window_params(from: 2.days.from_now, to: 3.days.from_now)
    { pickup_datetime: from.iso8601, scheduled_return_datetime: to.iso8601 }
  end

  def availability_row(params)
    get "/api/#{@org.slug}/availability", params: params
    assert_response :ok, response.body
    row = response.parsed_body["data"].find { |r| r["id"] == @category.id }
    assert_not_nil row, "the category should appear in the availability results"
    row
  end

  # AC-1: the guest-facing search returns class specs, seating, baggage and the
  # effective daily rate for the requested window — with no token at all.
  test "availability lists matching categories with specs and rate, unauthenticated (AC-1)" do
    row = availability_row(window_params)

    assert row["name"].present?
    assert row["daily_rate"].positive?
    assert_equal 5, row["passenger_capacity"]
    assert_equal 3, row["baggage_capacity"]
    assert_equal "automatic", row["transmission"]
    assert_equal 1, row["available_count"]
    assert_equal true, row["available"]
  end

  # AC-112 (Extra, conditional): a car whose status is not `available` is never
  # offered, even when it exists in the fleet.
  test "a vehicle in maintenance is not bookable (AC-112 / AC-72)" do
    @vehicle.update!(status: "maintenance")

    row = availability_row(window_params)
    assert_equal 0, row["available_count"]
    assert_equal false, row["available"]

    # The maintenance gate is the mechanism: an active work order forces the
    # status, so the vehicle drops out of online availability without any
    # endpoint change.
    @vehicle.update!(status: "available")
    VehicleMaintenanceLog.create!(
      organization: @org, vehicle: @vehicle, service_type: "oil_change",
      service_date: Date.current, status: "scheduled"
    )
    assert_equal "maintenance", @vehicle.reload.status
    assert_equal 0, availability_row(window_params)["available_count"]
  end

  # AC-112 (Extra, conditional): an existing live contract overlapping the
  # requested window removes the vehicle from the available set.
  test "a vehicle with an overlapping reservation is not bookable (AC-112)" do
    Rental.create!(
      organization: @org, customer_profile: @graph[:profile], vehicle_category: @category,
      vehicle: @vehicle, location: @graph[:location], reservation_number: "DF-OVL-#{SecureRandom.hex(3)}",
      pickup_datetime: 1.day.from_now, scheduled_return_datetime: 4.days.from_now,
      scheduled_duration_days: 3, status: "reserved", protection_tier: "basic"
    )

    row = availability_row(window_params(from: 2.days.from_now, to: 3.days.from_now))
    assert_equal 0, row["available_count"]
  end

  # AC-112 (Extra, edge): a contract that does NOT overlap the requested window
  # leaves the vehicle bookable.
  test "a non-overlapping reservation leaves the vehicle bookable (AC-112)" do
    Rental.create!(
      organization: @org, customer_profile: @graph[:profile], vehicle_category: @category,
      vehicle: @vehicle, location: @graph[:location], reservation_number: "DF-FAR-#{SecureRandom.hex(3)}",
      pickup_datetime: 10.days.from_now, scheduled_return_datetime: 12.days.from_now,
      scheduled_duration_days: 2, status: "reserved", protection_tier: "basic"
    )

    row = availability_row(window_params(from: 2.days.from_now, to: 3.days.from_now))
    assert_equal 1, row["available_count"]
  end

  # AC-112 / AC-4: a cancelled/completed contract never blocks availability
  # (only reserved|confirmed|active|overdue are live).
  test "a completed contract does not block availability (AC-112)" do
    @graph[:rental].update!(status: "completed",
                            pickup_datetime: 1.day.from_now,
                            scheduled_return_datetime: 4.days.from_now)

    assert_equal 1, availability_row(window_params)["available_count"]
  end

  # AC-1: the response echoes the resolved organization and window so the SPA
  # can key its results on the branch it is booking.
  test "availability echoes the organization and requested window (AC-1)" do
    get "/api/#{@org.slug}/availability", params: window_params
    assert_response :ok
    meta = response.parsed_body["meta"]
    assert_equal @org.slug, meta["organization"]
    assert_not_nil meta["pickup_datetime"]
    assert_not_nil meta["return_datetime"]
  end

  # AC-112 (tenant isolation): another organization's fleet never leaks into the
  # public catalogue of this branch.
  test "availability never leaks another organization's fleet (AC-112)" do
    foreign = build_rental_graph(organization: @other_org)

    get "/api/#{@org.slug}/availability", params: window_params
    assert_response :ok
    ids = response.parsed_body["data"].map { |r| r["id"] }
    assert_not_includes ids, foreign[:category].id
  end
end
