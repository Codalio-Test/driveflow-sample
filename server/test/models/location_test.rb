# frozen_string_literal: true

require "test_helper"

# AC-5 — Location data model (postal code, branch metadata, tenancy).
class LocationTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "location-org")
    @location = Location.create!(
      organization: @org, name: "SFO Terminal 2", code: "SFO-01", address: "780 N Access Rd",
      city: "San Francisco", state: "CA", postal_code: "94128",
      phone: "+1-650-555-0144", email: "sfo@driveflow.com", is_active: true
    )
  end

  test "postal code is stored and exposed (AC-5)" do
    assert_equal "94128", @location.postal_code
    assert_equal "94128", @location.as_json["postal_code"]
  end

  test "name and code are required" do
    blank = Location.new(organization: @org)
    assert_not blank.valid?
    assert_includes blank.errors.attribute_names, :name
    assert_includes blank.errors.attribute_names, :code
  end

  test "computed label combines code and name" do
    assert_equal "SFO-01 · SFO Terminal 2", @location.rhino_computed_attributes["label"]
  end

  test "locations are organization scoped" do
    other = create_organization(slug: "location-other-org")
    foreign = Location.create!(organization: other, name: "LAX", code: "LAX-01", is_active: true)
    assert_equal [@location.id], Location.unscoped.for_organization(@org).pluck(:id)
    assert_not_includes Location.unscoped.for_organization(@org).pluck(:id), foreign.id
  end

  test "guests only see active branches" do
    closed = Location.create!(organization: @org, name: "Closed", code: "CLD-1", is_active: false)
    visible = Scopes::LocationScope.new.apply(Location.unscoped).pluck(:id)
    assert_includes visible, @location.id
    assert_not_includes visible, closed.id
  end
end
