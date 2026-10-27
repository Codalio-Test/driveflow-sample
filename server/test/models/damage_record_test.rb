# frozen_string_literal: true

require "test_helper"

# AC-11 / AC-48 / AC-52 — DamageRecord (repair flag, new-damage photo rule).
class DamageRecordTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "damage-org")
    @graph = build_rental_graph(organization: @org)
    @inspection = Inspection.create!(
      organization: @org, rental: @graph[:rental], vehicle: @graph[:vehicle],
      inspection_type: "check_in", odometer_reading: 10_400, fuel_percentage: 75, status: "completed"
    )
  end

  test "repaired flag is persisted (AC-11)" do
    record = DamageRecord.create!(
      organization: @org, inspection: @inspection, vehicle: @graph[:vehicle],
      panel_location: "front_bumper", severity: "minor_scratch", description: "scuff",
      is_pre_existing: true, repaired: false
    )
    assert_equal false, record.repaired
    record.update!(repaired: true)
    assert record.reload.repaired
  end

  test "panel location and severity are required and severity is a closed set" do
    blank = DamageRecord.new(organization: @org, inspection: @inspection, vehicle: @graph[:vehicle])
    assert_not blank.valid?
    assert_includes blank.errors.attribute_names, :panel_location
    assert_includes blank.errors.attribute_names, :severity
  end

  test "newly discovered damage mandates a photo (AC-52)" do
    new_damage = DamageRecord.new(
      organization: @org, inspection: @inspection, vehicle: @graph[:vehicle],
      panel_location: "wheel_rim_front_right", severity: "dent",
      description: "curb rash", is_pre_existing: false
    )
    assert_not new_damage.valid?
    assert_includes new_damage.errors[:photo_url], "is required for newly discovered damage"

    new_damage.photo_url = "https://example.com/rash.jpg"
    assert new_damage.valid?
  end

  test "pre-existing damage needs no photo" do
    pre = DamageRecord.new(
      organization: @org, inspection: @inspection, vehicle: @graph[:vehicle],
      panel_location: "rear_bumper", severity: "minor_scratch",
      description: "old chip", is_pre_existing: true
    )
    assert pre.valid?
  end

  test "computed attributes flag new damage for the comparison view" do
    record = DamageRecord.create!(
      organization: @org, inspection: @inspection, vehicle: @graph[:vehicle],
      panel_location: "driver_door", severity: "dent", description: "fresh dent",
      photo_url: "https://example.com/dent.jpg", is_pre_existing: false, repair_cost_estimate: 220
    )
    attrs = record.rhino_computed_attributes
    assert attrs["new_damage"]
    assert_equal 220.0, attrs["cost"]
    assert_equal "driver_door · Dent", attrs["label"]
  end
end
