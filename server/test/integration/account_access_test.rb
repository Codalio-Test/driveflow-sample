# frozen_string_literal: true

require "test_helper"

# AC-23 / AC-24 / AC-67 / AC-68 / AC-118 — the authenticated customer portal
# data surface: every /account/* view is backed by a token-protected endpoint.
class AccountAccessTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization(slug: "account-org")
    @customer_role = create_role(slug: "customer")
    @manager_role = create_role(slug: "fleet_manager")
    grant(@org, @customer_role,
          "rentals.index", "rentals.show", "customer_profiles.index", "customer_profiles.show",
          "customer_profiles.update", "payments.index", "payments.show", "receipts.index", "receipts.show")
    crud!(@org, @manager_role, "rentals", "customer_profiles", "payments")

    @customer = member_of(@org, role_slug: "customer", role: @customer_role,
                                email: "account-customer@example.com")
    @graph = build_rental_graph(organization: @org)
    @graph[:profile].update!(user: @customer)
  end

  def json_headers
    { "Content-Type" => "application/json" }
  end

  test "account endpoints reject unauthenticated callers (AC-23 / AC-68 / AC-118)" do
    %w[rentals customer_profiles payments].each do |slug|
      get "/api/#{@org.slug}/#{slug}"
      assert_response :unauthorized, "#{slug} should require a token"
    end

    get "/api/#{@org.slug}/receipts"
    assert_response :unauthorized
  end

  test "an authenticated customer can read their bookings (AC-24)" do
    get "/api/#{@org.slug}/rentals", headers: auth_headers(@customer)
    assert_response :ok
    assert_equal @graph[:rental].reservation_number,
                 response.parsed_body["data"].first["reservation_number"]
  end

  test "the bookings response carries the display contract the SPA renders (AC-24)" do
    get "/api/#{@org.slug}/rentals", headers: auth_headers(@customer)
    assert_response :ok
    row = response.parsed_body["data"].first
    assert row.key?("customer")
    assert row.key?("vehicle")
    assert row.key?("due")
    assert row.key?("dates")
    assert row.key?("deposit_status")
  end

  test "a customer can update their own profile (AC-117)" do
    put "/api/#{@org.slug}/customer_profiles/#{@graph[:profile].id}",
        params: { full_name: "David Chen Jr", phone_number: "+1-415-555-9999" }.to_json,
        headers: json_headers.merge(auth_headers(@customer))

    assert_response :ok
    assert_equal "David Chen Jr", @graph[:profile].reload.full_name
  end

  test "a customer cannot update someone else's profile" do
    other = build_rental_graph(organization: @org)[:profile]

    put "/api/#{@org.slug}/customer_profiles/#{other.id}",
        params: { full_name: "Hijacked" }.to_json,
        headers: json_headers.merge(auth_headers(@customer))

    assert_not_equal "Hijacked", other.reload.full_name
  end

  test "billing history exposes payments with receipt references (AC-67)" do
    Payment.create!(organization: @org, rental: @graph[:rental], customer_profile: @graph[:profile],
                    transaction_type: "deposit_capture", amount: 40, status: "succeeded",
                    payment_method_last4: "4242", processed_at: Time.current,
                    stripe_charge_key: "ch_account_test")

    get "/api/#{@org.slug}/payments", headers: auth_headers(@customer)
    assert_response :ok
    row = response.parsed_body["data"].first
    assert_equal "Deposit capture", row["type"]
    assert_equal "4242", row["last4"]
    assert_equal "ch_account_test", row["reference"]
  end

  test "only the customer role resolves the account dashboard role gate (AC-26)" do
    manager = member_of(@org, role_slug: "fleet_manager", role: @manager_role,
                              email: "account-manager@example.com")

    assert_equal "customer", @customer.role_slug_for_validation(@org)
    assert_equal "fleet_manager", manager.role_slug_for_validation(@org)
  end

  # AC-26: the client's /account/* guard reads the caller's role set from /me —
  # a `customer` carries the role that unlocks the portal, and a staff member in
  # the same organization does not. This is what stops a counter agent or a
  # fleet manager landing inside the renter portal.
  test "/me resolves the role the account guard gates on (AC-26)" do
    get "/api/#{@org.slug}/me", headers: auth_headers(@customer)
    assert_response :ok
    assert_equal ["customer"], response.parsed_body["role_slugs"]
    assert_equal @graph[:profile].id, response.parsed_body["customer_profile_id"]

    counter_role = create_role(slug: "counter_agent")
    counter = member_of(@org, role_slug: "counter_agent", role: counter_role,
                              email: "account-counter-gate@example.com")
    get "/api/#{@org.slug}/me", headers: auth_headers(counter)
    assert_response :ok
    assert_equal ["counter_agent"], response.parsed_body["role_slugs"]
    assert_not_includes response.parsed_body["role_slugs"], "customer"
  end
end
