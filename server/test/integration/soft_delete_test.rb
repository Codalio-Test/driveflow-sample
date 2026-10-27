# frozen_string_literal: true

require "test_helper"

# Soft-delete behaviour over the real API: a discarded record must disappear from
# the index but remain visible to /trashed, and the two must never overlap.
#
# Regression guard: Rhino's index action queries the model class directly (it
# never calls `.kept`), and its organization scoping is
# `relation.merge(model.for_organization(org))` — so a naive soft-delete default
# scope either leaked discarded rows into the index or clobbered the `/trashed`
# condition and returned live rows.
class SoftDeleteTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization(slug: "softdelete-org")
    @role = create_role(slug: "fleet_manager")
    crud!(@org, @role, "vehicle_categories")
    grant(@org, @role, "vehicle_categories.trashed", "vehicle_categories.restore")
    @manager = member_of(@org, role_slug: "fleet_manager", role: @role, email: "soft-manager@example.com")
    @category = VehicleCategory.create!(organization: @org, name: "Soft Probe", code: "SOFT-1",
                                        base_daily_rate: 10, security_deposit_amount: 10)
  end

  def json_headers
    { "Content-Type" => "application/json" }.merge(auth_headers(@manager))
  end

  test "a live record appears in the index and not in the trash" do
    get "/api/#{@org.slug}/vehicle_categories", headers: auth_headers(@manager)
    assert_includes ids(response), @category.id

    get "/api/#{@org.slug}/vehicle_categories/trashed", headers: auth_headers(@manager)
    assert_not_includes ids(response), @category.id
  end

  test "a discarded record leaves the index and enters the trash" do
    delete "/api/#{@org.slug}/vehicle_categories/#{@category.id}", headers: json_headers
    assert_response :no_content
    assert_not_nil @category.reload.discarded_at

    get "/api/#{@org.slug}/vehicle_categories", headers: auth_headers(@manager)
    assert_not_includes ids(response), @category.id

    get "/api/#{@org.slug}/vehicle_categories/trashed", headers: auth_headers(@manager)
    assert_includes ids(response), @category.id
  end

  test "a discarded record is restored" do
    @category.discard

    post "/api/#{@org.slug}/vehicle_categories/#{@category.id}/restore", headers: json_headers
    assert_response :success
    assert_nil @category.reload.discarded_at
  end

  test "the trash is never served cross-tenant" do
    other = create_organization(slug: "softdelete-other-org")
    foreign = VehicleCategory.create!(organization: other, name: "Foreign", code: "FOR-1",
                                      base_daily_rate: 10, security_deposit_amount: 10)
    foreign.discard

    get "/api/#{@org.slug}/vehicle_categories/trashed", headers: auth_headers(@manager)
    assert_not_includes ids(response), foreign.id
  end

  test "the soft-delete default scope only affects reads, not creation" do
    fresh = VehicleCategory.create!(organization: @org, name: "Fresh", code: "FRESH-1",
                                    base_daily_rate: 20, security_deposit_amount: 20)
    assert fresh.persisted?
    assert_nil fresh.discarded_at
  end

  private

  def ids(response_body)
    response_body.parsed_body["data"].map { |row| row["id"] }
  end
end
