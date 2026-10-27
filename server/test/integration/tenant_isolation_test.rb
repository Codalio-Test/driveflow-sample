# frozen_string_literal: true

require "test_helper"

# AC-114 — tenant isolation and customer row-level scoping over HTTP.
class TenantIsolationTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization(slug: "iso-org")
    @other_org = create_organization(slug: "iso-other-org")
    @role = create_role(slug: "fleet_manager")
    @customer_role = create_role(slug: "customer")
    crud!(@org, @role, "rentals", "vehicle_categories", "payments", "customer_profiles")
    crud!(@other_org, @role, "rentals", "vehicle_categories")

    @admin = member_of(@org, role_slug: "fleet_manager", role: @role, email: "iso-admin@example.com")
    @graph = build_rental_graph(organization: @org)
    @foreign = build_rental_graph(organization: @other_org)
  end

  test "a member cannot read another organization's resources" do
    get "/api/#{@other_org.slug}/rentals", headers: auth_headers(@admin)
    assert_response :not_found
  end

  test "an unknown organization slug hides existence" do
    get "/api/does-not-exist/rentals", headers: auth_headers(@admin)
    assert_response :not_found
  end

  test "index only returns rows from the resolved organization" do
    get "/api/#{@org.slug}/rentals", headers: auth_headers(@admin)
    assert_response :ok
    ids = response.parsed_body["data"].map { |row| row["id"] }
    assert_includes ids, @graph[:rental].id
    assert_not_includes ids, @foreign[:rental].id
  end

  test "show on a foreign record is a 404, not a 403" do
    get "/api/#{@org.slug}/rentals/#{@foreign[:rental].id}", headers: auth_headers(@admin)
    assert_response :not_found
  end

  test "organization_id is set server side and cannot be overridden (AC-114)" do
    post "/api/#{@org.slug}/vehicle_categories",
         params: { name: "Smuggled", code: "SMUG-#{SecureRandom.hex(2)}", base_daily_rate: 10,
                   security_deposit_amount: 10, organization_id: @other_org.id }.to_json,
         headers: json_headers(auth_headers(@admin))

    assert_response :created
    assert_equal @org.id, VehicleCategory.find(response.parsed_body["id"]).organization_id
  end

  test "a customer only ever sees its own rentals (AC-114)" do
    customer = member_of(@org, role_slug: "customer", role: @customer_role,
                              email: "iso-customer@example.com")
    mine = build_rental_graph(organization: @org)
    mine[:profile].update!(user: customer)
    theirs = build_rental_graph(organization: @org)
    grant(@org, @customer_role, "rentals.index", "rentals.show")

    get "/api/#{@org.slug}/rentals", headers: auth_headers(customer)
    assert_response :ok
    ids = response.parsed_body["data"].map { |row| row["id"] }
    assert_includes ids, mine[:rental].id
    assert_not_includes ids, theirs[:rental].id
  end

  test "a customer cannot read another renter's payment history (AC-114)" do
    customer = member_of(@org, role_slug: "customer", role: @customer_role,
                              email: "iso-customer2@example.com")
    mine = build_rental_graph(organization: @org)
    mine[:profile].update!(user: customer)
    Payment.create!(organization: @org, rental: mine[:rental], customer_profile: mine[:profile],
                    transaction_type: "deposit_hold", amount: 300, status: "succeeded",
                    processed_at: Time.current)
    # A second renter in the SAME organization must stay invisible.
    other_graph = build_rental_graph(organization: @org)
    foreign_payment = Payment.create!(organization: @org, rental: other_graph[:rental],
                                      customer_profile: other_graph[:profile],
                                      transaction_type: "deposit_hold", amount: 300,
                                      status: "succeeded", processed_at: Time.current)
    grant(@org, @customer_role, "payments.index", "payments.show")

    get "/api/#{@org.slug}/payments", headers: auth_headers(customer)
    assert_response :ok
    ids = response.parsed_body["data"].map { |row| row["id"] }
    assert_not_includes ids, foreign_payment.id
  end

  private

  def json_headers(extra = {})
    { "Content-Type" => "application/json" }.merge(extra)
  end
end
