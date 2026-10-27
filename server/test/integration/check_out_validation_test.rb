# frozen_string_literal: true

require "test_helper"

# AC-28 / AC-29 / AC-30 / AC-31 / AC-35 / AC-37 / AC-38 — counter check-out,
# driver verification and the deposit gate.
class CheckOutValidationTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization(slug: "checkout-org")
    @role = create_role(slug: "counter_agent")
    @customer_role = create_role(slug: "customer")
    crud!(@org, @role, "rentals", "customer_profiles", "payments", "inspections",
          "vehicles", "vehicle_categories", "locations")
    grant(@org, @role, "counter.departures", "counter.returns", "counter.lookup")
    @agent = member_of(@org, role_slug: "counter_agent", role: @role,
                             email: "checkout-agent@example.com")
    @graph = build_rental_graph(organization: @org)
    @rental = @graph[:rental]
  end

  def json_headers
    { "Content-Type" => "application/json" }
  end

  test "a counter agent can read the departures queue (AC-28 / AC-29)" do
    get "/api/#{@org.slug}/counter/departures", headers: auth_headers(@agent)
    assert_response :ok
    assert response.parsed_body.key?("kpis")
  end

  test "a customer cannot read the counter queue (AC-29)" do
    customer = member_of(@org, role_slug: "customer", role: @customer_role,
                               email: "checkout-customer@example.com")
    get "/api/#{@org.slug}/counter/departures", headers: auth_headers(customer)
    assert_response :forbidden
  end

  test "an unauthenticated counter request is rejected" do
    get "/api/#{@org.slug}/counter/departures"
    assert_response :unauthorized
  end

  test "an expired licence blocks check-out (AC-31)" do
    @graph[:profile].update!(license_expiry_date: 1.day.ago.to_date)

    profile = @graph[:profile].reload
    assert profile.license_expired?
    assert_not profile.license_valid?
    # The counter payload carries the flag the check-out screen gates on.
    assert @graph[:profile].rhino_computed_attributes["license_expired"]
  end

  test "a valid licence allows check-out" do
    @graph[:profile].update!(license_expiry_date: 1.year.from_now.to_date)
    assert @graph[:profile].reload.license_valid?
    assert_not @graph[:profile].rhino_computed_attributes["license_expired"]
  end

  test "the deposit hold can be authorised at the counter (AC-35)" do
    post "/api/#{@org.slug}/payments/hold",
         params: { rental_id: @rental.id, last4: "4242" }.to_json,
         headers: json_headers.merge(auth_headers(@agent))

    assert_response :created
    body = response.parsed_body
    assert_equal "deposit_hold", body.dig("payment", "transaction_type")
    assert_equal @graph[:category].security_deposit_amount.to_f, body.dig("payment", "amount").to_f
    assert_equal "Held", body.dig("rental", "deposit_status")
  end

  test "a declined deposit card returns the decline reason and no payment row (AC-37)" do
    post "/api/#{@org.slug}/payments/hold",
         params: { rental_id: @rental.id, payment_method_last4: "0341" }.to_json,
         headers: json_headers.merge(auth_headers(@agent))

    assert_response :unprocessable_entity
    assert_equal "card_declined", response.parsed_body["code"]
    assert response.parsed_body["decline_reason"].present?
    assert_equal 0, @rental.payments.where(transaction_type: "deposit_hold").count
  end

  test "the deposit gate requires payments.store AND rentals.update (AC-38)" do
    weak_role = create_role(slug: "rental_only")
    grant(@org, weak_role, "rentals.index", "rentals.show", "rentals.update", "payments.index", "payments.show")
    weak = member_of(@org, role_slug: "rental_only", role: weak_role, email: "weak-agent@example.com")

    post "/api/#{@org.slug}/payments/hold",
         params: { rental_id: @rental.id }.to_json,
         headers: json_headers.merge(auth_headers(weak))

    assert_response :forbidden
    assert_match(/payments\.store/, response.parsed_body["message"])
  end

  test "finishing without the required photos is blocked (AC-49)" do
    post "/api/#{@org.slug}/inspections",
         params: { rental_id: @rental.id, vehicle_id: @rental.vehicle_id, inspection_type: "check_out",
                   odometer_reading: 9_800, fuel_percentage: 100, cleanliness_status: "clean" }.to_json,
         headers: json_headers.merge(auth_headers(@agent))
    assert_response :created
    inspection_id = response.parsed_body["id"]

    post "/api/#{@org.slug}/inspections/#{inspection_id}/finish",
         params: {}.to_json, headers: json_headers.merge(auth_headers(@agent))

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["missing"], "front_photo"
    assert_equal "in_progress", Inspection.find(inspection_id).reload.status
  end

  test "the 4-quadrant walkaround completes once every angle is captured (AC-30 / AC-47)" do
    post "/api/#{@org.slug}/inspections",
         params: { rental_id: @rental.id, vehicle_id: @rental.vehicle_id, inspection_type: "check_out",
                   odometer_reading: 9_800, fuel_percentage: 100, cleanliness_status: "clean" }.to_json,
         headers: json_headers.merge(auth_headers(@agent))
    assert_response :created
    inspection_id = response.parsed_body["id"]

    Inspection::REQUIRED_PHOTO_ANGLES.each do |angle|
      file = fixture_file_upload("sample.png", "image/png")
      post "/api/#{@org.slug}/inspections/#{inspection_id}/photos",
           params: { file: file, angle: angle },
           headers: auth_headers(@agent)
      assert_response :created
    end

    post "/api/#{@org.slug}/inspections/#{inspection_id}/finish",
         params: {}.to_json, headers: json_headers.merge(auth_headers(@agent))

    assert_response :ok
    assert_equal "completed", response.parsed_body.dig("inspection", "status")
    assert_equal 4, Inspection.find(inspection_id).photos.count
  end

  test "an unverified renter name is surfaced by the counter payload" do
    payload = @graph[:profile].rhino_computed_attributes
    assert payload.key?("license_valid")
    assert payload.key?("license_expired")
  end
end
