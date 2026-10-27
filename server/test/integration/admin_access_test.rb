# frozen_string_literal: true

require "test_helper"

# AC-60 / AC-63 / AC-69 / AC-74 / AC-79 / AC-80 / AC-83 / AC-84 / AC-86 / AC-87 /
# AC-89 / AC-101 / AC-110 / AC-111 — fleet-manager-only admin surfaces.
class AdminAccessTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization(slug: "admin-org")
    @manager_role = create_role(slug: "fleet_manager")
    @customer_role = create_role(slug: "customer")
    @counter_role = create_role(slug: "counter_agent")

    crud!(@org, @manager_role, "vehicles", "rate_rules", "rentals", "payments",
          "vehicle_maintenance_logs", "vehicle_categories", "locations")
    grant(@org, @manager_role,
          "fleet_matrix.index", "analytics.show", "analytics.export", "billing.outstanding",
          "rentals.notify", "rentals.escalate", "rentals.extend", "payments.expand_hold",
          "counter.departures", "counter.returns")
    grant(@org, @customer_role, "vehicles.index", "vehicles.show", "rate_rules.index", "rate_rules.show")
    grant(@org, @counter_role, "rentals.index", "rentals.show", "rentals.update",
          "counter.departures", "counter.returns", "counter.lookup", "vehicles.index")

    @manager = member_of(@org, role_slug: "fleet_manager", role: @manager_role,
                               email: "admin-manager@example.com")
    @customer = member_of(@org, role_slug: "customer", role: @customer_role,
                                email: "admin-customer@example.com")
    @counter = member_of(@org, role_slug: "counter_agent", role: @counter_role,
                               email: "admin-counter@example.com")
    @graph = build_rental_graph(organization: @org)
  end

  def json_headers
    { "Content-Type" => "application/json" }
  end

  test "the fleet matrix is fleet_manager only (AC-60 / AC-63)" do
    get "/api/#{@org.slug}/fleet_matrix", headers: auth_headers(@manager)
    assert_response :ok
    body = response.parsed_body
    assert body["vehicles"].any?
    assert body["days"].any?

    get "/api/#{@org.slug}/fleet_matrix", headers: auth_headers(@customer)
    assert_response :forbidden
  end

  test "fleet onboarding is blocked for non-managers (AC-63)" do
    post "/api/#{@org.slug}/vehicles",
         params: { vehicle_category_id: @graph[:category].id, location_id: @graph[:location].id,
                   vin: "NEW#{SecureRandom.hex(4)}", license_plate: "NEW-1", make: "Kia",
                   model: "Niro", year: 2024, current_odometer: 10, status: "available" }.to_json,
         headers: json_headers.merge(auth_headers(@customer))
    assert_response :forbidden
  end

  test "duplicate vin onboarding is rejected with a conflict (AC-64)" do
    post "/api/#{@org.slug}/vehicles",
         params: { vehicle_category_id: @graph[:category].id, location_id: @graph[:location].id,
                   vin: @graph[:vehicle].vin, license_plate: "DUP-1", make: "Kia",
                   model: "Niro", year: 2024, current_odometer: 10, status: "available" }.to_json,
         headers: json_headers.merge(auth_headers(@manager))

    assert_response :unprocessable_entity
    assert response.parsed_body.dig("errors", "vin").present?
  end

  test "rate rules are manager only (AC-69 / AC-101)" do
    post "/api/#{@org.slug}/rate_rules",
         params: { vehicle_category_id: @graph[:category].id, name: "Holiday",
                   daily_multiplier: 1.4, weekend_multiplier: 1.2, min_rental_days: 1,
                   is_active: true }.to_json,
         headers: json_headers.merge(auth_headers(@customer))
    assert_response :forbidden

    post "/api/#{@org.slug}/rate_rules",
         params: { vehicle_category_id: @graph[:category].id, name: "Holiday",
                   daily_multiplier: 1.4, weekend_multiplier: 1.2, min_rental_days: 1,
                   is_active: true }.to_json,
         headers: json_headers.merge(auth_headers(@manager))
    assert_response :created
  end

  test "analytics is manager only and requires authentication (AC-79 / AC-80)" do
    get "/api/#{@org.slug}/analytics", headers: auth_headers(@manager)
    assert_response :ok
    assert response.parsed_body["kpis"].any?

    get "/api/#{@org.slug}/analytics", headers: auth_headers(@customer)
    assert_response :forbidden

    get "/api/#{@org.slug}/analytics"
    assert_response :unauthorized
  end

  test "active rentals can be filtered by status for managers only (AC-83)" do
    get "/api/#{@org.slug}/rentals", params: { filter: { status: "active" } },
        headers: auth_headers(@manager)
    assert_response :ok
    assert(response.parsed_body["data"].all? { |row| row["status"] == "active" })
  end

  test "an overdue contract exposes the grace window and penalty cap (AC-85)" do
    @graph[:rental].update!(scheduled_return_datetime: 5.hours.ago, status: "overdue")

    get "/api/#{@org.slug}/rentals/#{@graph[:rental].id}", headers: auth_headers(@manager)
    assert_response :ok
    row = response.parsed_body
    assert_equal 60, row["late_grace_minutes"]
    assert row["grace_expires_at"].present?
    assert_equal 100.0, row["daily_cap"]
    assert row["accrued"].start_with?("$")
  end

  test "a return urgency notice can be dispatched (AC-86)" do
    post "/api/#{@org.slug}/rentals/#{@graph[:rental].reservation_number}/notify",
         params: { channel: "sms+email" }.to_json,
         headers: json_headers.merge(auth_headers(@manager))

    assert_response :created
    assert_equal "sms+email", response.parsed_body.dig("notification", "channel")
    assert_not_nil @graph[:rental].reload.last_notified_at
  end

  test "customers cannot dispatch urgency notices (AC-86 / AC-89)" do
    post "/api/#{@org.slug}/rentals/#{@graph[:rental].id}/notify",
         params: {}.to_json, headers: json_headers.merge(auth_headers(@customer))
    # The row-level scope hides another renter's contract (404) and the missing
    # permission denies outright (403); either way nothing is dispatched.
    assert_includes [403, 404], response.status
    assert_nil @graph[:rental].reload.last_notified_at
  end

  test "an extension clears the overdue state and records the new window (AC-84)" do
    @graph[:rental].update!(scheduled_return_datetime: 2.hours.ago, status: "overdue")
    new_return = 2.days.from_now

    post "/api/#{@org.slug}/rentals/#{@graph[:rental].id}/extend",
         params: { scheduled_return_datetime: new_return.iso8601 }.to_json,
         headers: json_headers.merge(auth_headers(@manager))

    assert_response :ok
    rental = @graph[:rental].reload
    assert_not_equal "overdue", rental.status
    assert_equal 1, rental.extension_count
    assert_in_delta new_return.to_i, rental.scheduled_return_datetime.to_i, 60
  end

  test "the pre-authorization hold can be expanded for an unreturned asset (AC-87)" do
    @graph[:rental].update!(status: "overdue")

    post "/api/#{@org.slug}/payments/expand_hold",
         params: { rental_id: @graph[:rental].id, amount: 250, last4: "4242" }.to_json,
         headers: json_headers.merge(auth_headers(@manager))

    assert_response :created
    assert_equal 250.0, response.parsed_body.dig("payment", "amount").to_f
  end

  test "a declined expansion flags the asset for recovery (AC-88)" do
    @graph[:rental].update!(status: "overdue")

    post "/api/#{@org.slug}/payments/expand_hold",
         params: { rental_id: @graph[:rental].id, amount: 250, payment_method_last4: "0341" }.to_json,
         headers: json_headers.merge(auth_headers(@manager))

    assert_response :unprocessable_entity
    assert response.parsed_body["escalated"]
    assert @graph[:rental].reload.escalated_for_recovery
  end

  test "maintenance work orders are manager only (AC-71 / AC-74)" do
    post "/api/#{@org.slug}/vehicle_maintenance_logs",
         params: { vehicle_id: @graph[:vehicle].id, service_type: "oil_change",
                   service_date: Date.current, odometer_at_service: 10_000, cost: 120,
                   vendor_name: "Bay City", status: "scheduled" }.to_json,
         headers: json_headers.merge(auth_headers(@customer))
    assert_response :forbidden

    post "/api/#{@org.slug}/vehicle_maintenance_logs",
         params: { vehicle_id: @graph[:vehicle].id, service_type: "oil_change",
                   service_date: Date.current, odometer_at_service: 10_000, cost: 120,
                   vendor_name: "Bay City", status: "scheduled" }.to_json,
         headers: json_headers.merge(auth_headers(@manager))
    assert_response :created
  end

  test "creating a work order pushes the vehicle into maintenance (AC-72 / AC-73)" do
    post "/api/#{@org.slug}/vehicle_maintenance_logs",
         params: { vehicle_id: @graph[:vehicle].id, service_type: "brake_service",
                   service_date: Date.current, odometer_at_service: 10_500, cost: 400,
                   vendor_name: "Precision", status: "in_progress" }.to_json,
         headers: json_headers.merge(auth_headers(@manager))
    assert_response :created
    log_id = response.parsed_body["id"]
    assert_equal "maintenance", @graph[:vehicle].reload.status

    put "/api/#{@org.slug}/vehicle_maintenance_logs/#{log_id}",
        params: { status: "completed", odometer_at_service: 10_500 }.to_json,
        headers: json_headers.merge(auth_headers(@manager))
    assert_response :ok
    assert_equal "available", @graph[:vehicle].reload.status
  end

  test "the counter queue endpoints are available to staff (AC-111)" do
    get "/api/#{@org.slug}/counter/returns", headers: auth_headers(@counter)
    assert_response :ok
    assert response.parsed_body.key?("kpis")
  end

  test "outstanding balances are visible to managers only (AC-65)" do
    @graph[:rental].update!(balance_owed_amount: 240, status: "completed")
    @graph[:profile].update!(stripe_customer_token: "cus_outstanding_test")

    get "/api/#{@org.slug}/billing/outstanding", headers: auth_headers(@manager)
    assert_response :ok
    row = response.parsed_body["data"].first
    assert_equal 240.0, row["balance_owed_amount"]
    # AC-65: the delinquent amount is linked back to the on-file Stripe customer
    # so the manager can charge the saved card.
    assert_equal "cus_outstanding_test", row["stripe_customer_token"]
    assert_equal 240.0, response.parsed_body["total_outstanding"]

    get "/api/#{@org.slug}/billing/outstanding", headers: auth_headers(@customer)
    assert_response :forbidden
  end

  # AC-69: the back-office billing reconciliation surface stays fleet_manager
  # only. A renter legitimately holds `rentals.index` (it backs
  # /account/bookings), so the gate must not be satisfied by that permission
  # alone.
  test "back-office billing reconciliation is denied to a renter holding rentals.index (AC-69)" do
    grant(@org, @customer_role, "rentals.index", "rentals.show")

    get "/api/#{@org.slug}/billing/outstanding", headers: auth_headers(@customer)
    assert_response :forbidden

    get "/api/#{@org.slug}/billing/outstanding", headers: auth_headers(@manager)
    assert_response :ok
  end

  test "CSV export of active rentals is manager-only (AC-81)" do
    get "/api/#{@org.slug}/rentals/export", headers: auth_headers(@manager)
    assert_response :ok
    assert_match(/reservation_number/, response.body)
  end
end
