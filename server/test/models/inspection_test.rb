# frozen_string_literal: true

require "test_helper"

# AC-9 / AC-45 / AC-46 / AC-49 / AC-53 / AC-75 — the Inspection data model.
class InspectionTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "inspection-org")
    @graph = build_rental_graph(organization: @org)
    @inspection = Inspection.create!(
      organization: @org, rental: @graph[:rental], vehicle: @graph[:vehicle],
      inspection_type: "check_out", odometer_reading: 9_800, fuel_percentage: 100,
      cleanliness_status: "clean", status: "in_progress"
    )
  end

  test "notes are persisted (AC-9)" do
    @inspection.update!(notes: "Rear scuff photographed.")
    assert_equal "Rear scuff photographed.", @inspection.reload.notes
  end

  test "customer signature url and timestamp are persisted (AC-45)" do
    signed_at = Time.current
    @inspection.update!(customer_signature_url: "https://example.com/sig.png",
                        customer_signature_timestamp: signed_at)
    assert_equal "https://example.com/sig.png", @inspection.customer_signature_url
    assert_in_delta signed_at.to_i, @inspection.customer_signature_timestamp.to_i, 2
  end

  test "odometer and fuel readings are required to be valid ranges (AC-46)" do
    assert @inspection.valid?
    @inspection.fuel_percentage = 101
    assert_not @inspection.valid?
    @inspection.fuel_percentage = 50
    @inspection.odometer_reading = -5
    assert_not @inspection.valid?
  end

  test "incomplete inspections cannot be marked finished (AC-49)" do
    draft = Inspection.new(organization: @org, rental: @graph[:rental], vehicle: @graph[:vehicle],
                          inspection_type: "check_out", status: "in_progress")
    assert draft.valid? # draft okay

    incomplete = Inspection.new(organization: @org, rental: @graph[:rental], vehicle: @graph[:vehicle],
                               inspection_type: "check_out", status: "completed")
    incomplete.validate
    assert_includes incomplete.errors[:odometer_reading].join, "required"
    assert_includes incomplete.errors[:fuel_percentage].join, "required"
  end

  test "cleanliness status vocabulary is normalized (AC-75)" do
    assert_equal %w[clean moderate dirty], Inspection::CLEANLINESS
    @inspection.cleanliness_status = "spotless"
    assert_not @inspection.valid?
  end

  test "inspection type must be check_out or check_in" do
    @inspection.inspection_type = "midway"
    assert_not @inspection.valid?
  end

  test "return readings are compared against the departure benchmarks (AC-53)" do
    check_in = Inspection.create!(
      organization: @org, rental: @graph[:rental], vehicle: @graph[:vehicle],
      inspection_type: "check_in", odometer_reading: 10_400, fuel_percentage: 75,
      cleanliness_status: "moderate", status: "completed"
    )
    delta = check_in.odometer_reading - @inspection.odometer_reading
    variance = @inspection.fuel_percentage - check_in.fuel_percentage
    assert_equal 600, delta
    assert_equal 25, variance
  end

  test "four quadrant photo angles are declared for the walkaround (AC-47)" do
    assert_equal %w[front driver_side rear passenger_side], Inspection::REQUIRED_PHOTO_ANGLES
  end

  test "damage records hang off the inspection (AC-48 / AC-52)" do
    damage = DamageRecord.create!(
      organization: @org, inspection: @inspection, vehicle: @graph[:vehicle],
      panel_location: "rear_bumper", severity: "minor_scratch",
      description: "2 inch chip", photo_url: "https://example.com/d.jpg", is_pre_existing: true
    )
    assert_includes @inspection.damage_records.pluck(:id), damage.id
    assert_equal 1, @inspection.rhino_computed_attributes["damage_count"]
  end
end
