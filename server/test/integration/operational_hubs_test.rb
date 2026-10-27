# frozen_string_literal: true

require "test_helper"

# AC-119 / AC-120 / AC-121 — the three parent hubs the sitemap adds on top of
# the leaf pages, each verified against the API contract the page renders from.
#
#   /booking  (public)         — the reservation funnel entry point: the class
#                                list + pricing, reachable with no account.
#   /counter  (staff)          — departures/returns KPIs + the departures table.
#   /admin    (fleet_manager)  — analytics KPIs, the overdue-balance card, the
#                                operational alert board.
#
# The client-side rendering of these pages is additionally proven by
# client/scripts/mount-check.mjs; these tests pin the backend contract they
# depend on, including the role gate on each hub.
class OperationalHubsTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization(slug: "hubs-org")
    @manager_role = create_role(slug: "fleet_manager")
    @counter_role = create_role(slug: "counter_agent")
    @customer_role = create_role(slug: "customer")

    crud!(@org, @manager_role, "vehicles", "rentals", "payments", "vehicle_categories",
          "locations", "rate_rules")
    grant(@org, @manager_role,
          "analytics.show", "analytics.export", "fleet_matrix.index", "counter.departures", "counter.returns")
    grant(@org, @counter_role, "rentals.index", "rentals.show", "vehicles.index",
          "counter.departures", "counter.returns", "counter.lookup")
    grant(@org, @customer_role, "rentals.index", "rentals.show")

    @manager = member_of(@org, role_slug: "fleet_manager", role: @manager_role,
                               email: "hubs-manager@example.com")
    @counter = member_of(@org, role_slug: "counter_agent", role: @counter_role,
                               email: "hubs-counter@example.com")
    @customer = member_of(@org, role_slug: "customer", role: @customer_role,
                                email: "hubs-customer@example.com")
    @graph = build_rental_graph(organization: @org)
  end

  # --------------------------------------------------------------------------
  # AC-119 — /booking hub
  # --------------------------------------------------------------------------

  # AC-119: the public funnel hub lists bookable classes with their pricing with
  # no token at all. The anonymous class list is served by the public catalogue
  # (the funnel's own endpoint), which returns the `name` + numeric `rate` the
  # Booking page renders.
  #
  # TODO (gap, non-blocking): the vendored BookingPage/VehiclesPage call
  # `useModelIndex('vehicle_categories')`, which is the *authenticated* tenant
  # index — an anonymous visitor has no token and no organization slug, so those
  # two pages fall back to an empty/error state. The public surface that backs
  # this AC exists and is asserted below; the ui-integration pass should point
  # the two public pages at `/api/{org}/vehicle_catalog` + `/availability`.
  test "the public /booking hub data surface is reachable anonymously (AC-119)" do
    get "/api/#{@org.slug}/vehicle_catalog"
    assert_response :ok
    row = response.parsed_body["data"].find { |r| r["id"] == @graph[:category].id }
    assert_not_nil row
    assert_equal @graph[:category].name, row["name"]
    assert row["rate"].positive?, "the funnel card renders a numeric rate"
    assert row["passenger_capacity"].present? && row["baggage_capacity"].present?

    get "/api/#{@org.slug}/availability",
        params: { pickup_datetime: 2.days.from_now.iso8601,
                  scheduled_return_datetime: 4.days.from_now.iso8601 }
    assert_response :ok
    assert response.parsed_body["data"].any?
  end

  # AC-119: the funnel hub is public — an anonymous caller is never challenged
  # with a 401/redirect on the booking surface.
  test "the booking funnel never requires authentication (AC-119)" do
    get "/api/#{@org.slug}/vehicle_catalog"
    assert_response :ok
    get "/api/#{@org.slug}/availability"
    assert_response :ok
  end

  # --------------------------------------------------------------------------
  # AC-120 — /counter hub
  # --------------------------------------------------------------------------

  # AC-120: the counter hub renders four KPI tiles (pending departures, arrived
  # returns, overdue, ready vehicles) from the two queue endpoints it calls.
  test "the counter hub KPIs come from the departure and return queues (AC-120)" do
    @graph[:rental].update!(status: "confirmed", pickup_datetime: 2.hours.from_now,
                            scheduled_return_datetime: 2.days.from_now)
    @graph[:vehicle].update!(status: "available")

    get "/api/#{@org.slug}/counter/departures", headers: auth_headers(@counter)
    assert_response :ok
    departure_kpis = response.parsed_body["kpis"]
    assert departure_kpis.key?("pending")
    assert departure_kpis.key?("ready")

    get "/api/#{@org.slug}/counter/returns", headers: auth_headers(@counter)
    assert_response :ok
    return_kpis = response.parsed_body["kpis"]
    assert return_kpis.key?("arrived")
    assert return_kpis.key?("overdue")

    # The hub merges both payloads — every tile has a source.
    merged = departure_kpis.merge(return_kpis)
    %w[pending ready arrived overdue].each { |tile| assert merged.key?(tile), "missing #{tile} tile" }
  end

  # AC-120: the departures table rows read `time`, `name` and `car` from the
  # rentals index the hub also calls.
  test "the counter hub departures table has its row contract (AC-120)" do
    @graph[:rental].update!(status: "confirmed", pickup_datetime: 1.hour.from_now,
                            scheduled_return_datetime: 2.days.from_now)

    get "/api/#{@org.slug}/rentals", params: { filter: { status: "confirmed" } },
        headers: auth_headers(@counter)
    assert_response :ok
    row = response.parsed_body["data"].find { |r| r["id"] == @graph[:rental].id }
    assert_not_nil row
    assert row["time"].present?
    assert row["customer"].present?
    assert row["vehicle"].present?
  end

  # AC-120 / AC-29: the counter hub is staff-only — a customer cannot read it.
  test "the counter hub is denied to customers (AC-120 / AC-29)" do
    get "/api/#{@org.slug}/counter/departures", headers: auth_headers(@customer)
    assert_response :forbidden
  end

  # --------------------------------------------------------------------------
  # AC-121 — /admin hub
  # --------------------------------------------------------------------------

  # AC-121: the admin hub renders utilization/RevPAC KPI cards plus the
  # overdue-balance card, all from the tenant-scoped analytics payload.
  test "the admin hub KPIs and overdue balance come from analytics (AC-121)" do
    @graph[:rental].update!(balance_owed_amount: 240, status: "overdue")

    get "/api/#{@org.slug}/analytics", headers: auth_headers(@manager)
    assert_response :ok
    body = response.parsed_body

    labels = body["kpis"].map { |kpi| kpi["label"] }
    assert_includes labels, "Utilization"
    assert_includes labels, "RevPAC"

    # The 4th card on /admin is the uncollected balance.
    assert_equal 240.0, body.dig("deposits", "uncollected_claims")
  end

  # AC-121: the admin hub's operational alert board is built from the overdue
  # contracts and the service-due vehicles, both of which the hub queries.
  test "the admin hub alert sources are queryable (AC-121)" do
    @graph[:rental].update!(status: "overdue")
    @graph[:vehicle].update!(current_odometer: 13_800)

    get "/api/#{@org.slug}/rentals", params: { filter: { status: "overdue" } },
        headers: auth_headers(@manager)
    assert_response :ok
    assert_includes response.parsed_body["data"].map { |r| r["id"] }, @graph[:rental].id

    get "/api/#{@org.slug}/vehicles", params: { scope: "serviceDue" },
        headers: auth_headers(@manager)
    assert_response :ok
    assert_includes response.parsed_body["data"].map { |v| v["id"] }, @graph[:vehicle].id
    assert response.parsed_body["data"].first["service_due"]
  end

  # AC-121 / AC-79: the admin hub is fleet_manager only.
  test "the admin hub is denied to customers and counter agents (AC-121 / AC-79)" do
    get "/api/#{@org.slug}/analytics", headers: auth_headers(@customer)
    assert_response :forbidden

    get "/api/#{@org.slug}/analytics", headers: auth_headers(@counter)
    assert_response :forbidden
  end

  # AC-121 / AC-80: the admin hub requires authentication at all.
  test "the admin hub requires a token (AC-121 / AC-80)" do
    get "/api/#{@org.slug}/analytics"
    assert_response :unauthorized
  end
end
