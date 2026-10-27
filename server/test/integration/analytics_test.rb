# frozen_string_literal: true

require "test_helper"

# AC-76 / AC-77 / AC-78 / AC-109 — tenant-safe analytics aggregates.
class AnalyticsTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization(slug: "analytics-org")
    @other_org = create_organization(slug: "analytics-other-org")
    @role = create_role(slug: "fleet_manager")
    crud!(@org, @role, "rentals", "vehicles", "payments", "vehicle_maintenance_logs")
    crud!(@other_org, @role, "rentals", "vehicles", "payments")
    grant(@org, @role, "analytics.show", "analytics.export", "fleet_matrix.index")

    @manager = member_of(@org, role_slug: "fleet_manager", role: @role,
                               email: "analytics-manager@example.com")
    @graph = build_rental_graph(organization: @org)
    @foreign = build_rental_graph(organization: @other_org)
  end

  test "analytics returns the utilization, RevPAC and deposit KPIs (AC-76 / AC-77)" do
    get "/api/#{@org.slug}/analytics", headers: auth_headers(@manager)
    assert_response :ok

    body = response.parsed_body
    labels = body["kpis"].map { |kpi| kpi["label"] }
    assert_includes labels, "Utilization"
    assert_includes labels, "RevPAC"
    assert_includes labels, "Damage recovery"
    assert body["deposits"].key?("total_held")
    assert body["deposits"].key?("released_in_full")
    assert body["deposits"].key?("partial_captures")
    assert body["deposits"].key?("uncollected_claims")
    assert_equal 3, body["charts"].size
  end

  test "the reporting range is honoured (AC-76)" do
    get "/api/#{@org.slug}/analytics", params: { range: 7 }, headers: auth_headers(@manager)
    assert_response :ok
    assert_equal 7, response.parsed_body["range"]

    get "/api/#{@org.slug}/analytics", params: { range: 90 }, headers: auth_headers(@manager)
    assert_equal 90, response.parsed_body["range"]
  end

  test "maintenance spend is broken down per vehicle class (AC-78)" do
    VehicleMaintenanceLog.create!(
      organization: @org, vehicle: @graph[:vehicle], service_type: "oil_change",
      service_date: Date.current, odometer_at_service: 10_000, cost: 185,
      vendor_name: "Bay City", status: "completed"
    )

    get "/api/#{@org.slug}/analytics", params: { range: 90 }, headers: auth_headers(@manager)
    assert_response :ok
    maintenance = response.parsed_body["maintenance"]
    assert maintenance.present?
    assert_equal 185.0, maintenance["total_spend"].to_f
    assert_equal 1, maintenance["completed_orders"]
  end

  test "analytics never aggregate another organization's data (AC-109)" do
    # Seed a distinguishable money trail in BOTH organizations.
    Payment.create!(organization: @org, rental: @graph[:rental], customer_profile: @graph[:profile],
                    transaction_type: "rental_payment", amount: 111, status: "succeeded",
                    processed_at: Time.current)
    Payment.create!(organization: @other_org, rental: @foreign[:rental],
                    customer_profile: @foreign[:profile], transaction_type: "rental_payment",
                    amount: 999_999, status: "succeeded", processed_at: Time.current)

    get "/api/#{@org.slug}/analytics", headers: auth_headers(@manager)
    assert_response :ok
    body = response.parsed_body

    revenue_kpi = body["kpis"].find { |kpi| kpi["label"] == "Revenue" }
    assert_equal "$111", revenue_kpi["value"]

    fleet_status = body["charts"].find { |chart| chart["title"] == "Fleet status" }
    assert_equal 1, fleet_status["values"].sum { |point| point["value"] }
  end

  test "a foreign manager cannot read this organization's analytics (AC-109)" do
    foreign_manager = member_of(@other_org, role_slug: "fleet_manager", role: @role,
                                           email: "analytics-foreign@example.com")
    get "/api/#{@org.slug}/analytics", headers: auth_headers(foreign_manager)
    assert_response :not_found
  end

  test "the fleet matrix only lists the requesting organization's vehicles (AC-110)" do
    get "/api/#{@org.slug}/fleet_matrix", headers: auth_headers(@manager)
    assert_response :ok
    plates = response.parsed_body["vehicles"].map { |v| v["plate"] }
    assert_includes plates, @graph[:vehicle].license_plate
    assert_not_includes plates, @foreign[:vehicle].license_plate
  end

  test "the analytics export returns CSV" do
    get "/api/#{@org.slug}/analytics/export", headers: auth_headers(@manager)
    assert_response :ok
    assert_match(/text\/csv/, response.media_type)
  end
end
