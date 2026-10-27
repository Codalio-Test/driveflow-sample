# frozen_string_literal: true

require "test_helper"

# AC-51 / AC-55 / AC-56 / AC-57 / AC-58 / AC-91 / AC-92 / AC-93 / AC-94 / AC-105 —
# return settlement: surcharge assessment, deposit capture + release, receipt PDF.
class SettlementTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization(slug: "settle-org")
    @role = create_role(slug: "counter_agent")
    crud!(@org, @role, "rentals", "payments", "inspections", "rental_charges",
          "vehicles", "customer_profiles", "vehicle_categories")
    grant(@org, @role, "counter.departures", "counter.returns", "counter.lookup")
    @agent = member_of(@org, role_slug: "counter_agent", role: @role, email: "settle-agent@example.com")
    @graph = build_rental_graph(organization: @org, initial_odometer: 10_000,
                                initial_fuel_percentage: 100)
    @rental = @graph[:rental]
    @rental.update!(status: "active", vehicle: @graph[:vehicle])
    StripePaymentService.new(organization: @org).hold(rental: @rental, amount: 300, last4: "4242")
    @check_in = Inspection.create!(
      organization: @org, rental: @rental, vehicle: @graph[:vehicle], inspection_type: "check_in",
      odometer_reading: 10_700, fuel_percentage: 50, cleanliness_status: "moderate",
      status: "completed", performed_at: Time.current
    )
    @rental.update!(final_odometer: 10_700, final_fuel_percentage: 50,
                    scheduled_return_datetime: 3.hours.ago, actual_return_datetime: Time.current)
  end

  def json_headers
    { "Content-Type" => "application/json" }
  end

  test "the settlement preview itemizes fuel, mileage and late lines (AC-91 / AC-92 / AC-93)" do
    get "/api/#{@org.slug}/rentals/#{@rental.id}/settlement_preview", headers: auth_headers(@agent)
    assert_response :ok

    settlement = response.parsed_body["settlement"]
    assert_equal 60, settlement["late_grace_minutes"]
    assert_equal 50.0, settlement["fuel_variance_percentage"]
    assert_equal 7.0, settlement["missing_fuel_gallons"]        # 14 gal × 50%
    assert_equal 56.0, settlement["refueling_charge"]           # × $8.00
    assert_equal 300, settlement["excess_miles"]                # 700 mi − 400 allowance
    assert_equal 105.0, settlement["excess_mileage_charge"]     # × $0.35
    assert_equal 70.0, settlement["late_fee"]                   # 2 billable hours × $35
    assert_equal 100.0, settlement["daily_cap"]
  end

  test "settling captures the charges and releases the difference (AC-56)" do
    post "/api/#{@org.slug}/payments/settle",
         params: { rental_id: @rental.id, inspection_id: @check_in.id }.to_json,
         headers: json_headers.merge(auth_headers(@agent))

    assert_response :created
    body = response.parsed_body
    assert_equal "deposit_capture", body.dig("capture", "transaction_type")
    assert_equal "deposit_release", body.dig("release", "transaction_type")
    assert_equal 300.0, (body.dig("capture", "amount").to_f + body.dig("release", "amount").to_f).round(2)
    assert_equal "completed", body.dig("rental", "status")
  end

  test "settlement moves the vehicle into turnaround cleaning (AC-58)" do
    post "/api/#{@org.slug}/payments/settle",
         params: { rental_id: @rental.id, inspection_id: @check_in.id }.to_json,
         headers: json_headers.merge(auth_headers(@agent))

    assert_response :created
    assert_equal "cleaning", @graph[:vehicle].reload.status
  end

  test "releasing in full leaves no capture row (AC-55)" do
    @check_in.update!(fuel_percentage: 100, odometer_reading: 10_000)
    @rental.update!(final_fuel_percentage: 100, final_odometer: 10_000,
                    scheduled_return_datetime: 1.minute.ago, actual_return_datetime: Time.current)

    post "/api/#{@org.slug}/payments/settle",
         params: { rental_id: @rental.id, inspection_id: @check_in.id }.to_json,
         headers: json_headers.merge(auth_headers(@agent))

    assert_response :created
    assert_nil response.parsed_body["capture"]
    assert_equal "deposit_release", response.parsed_body.dig("release", "transaction_type")
  end

  test "charges exceeding the hold are flagged for balance recovery (AC-57)" do
    @rental.vehicle.update!(fuel_tank_capacity_gallons: 60)
    @check_in.update!(fuel_percentage: 0, odometer_reading: 12_000)

    post "/api/#{@org.slug}/payments/settle",
         params: { rental_id: @rental.id, inspection_id: @check_in.id }.to_json,
         headers: json_headers.merge(auth_headers(@agent))

    assert_response :created
    assert response.parsed_body["invoice_required"]
    assert @rental.reload.balance_owed_amount.positive?
  end

  test "the itemized receipt PDF is generated (AC-105 / AC-58)" do
    get "/api/#{@org.slug}/receipts/#{@rental.id}", headers: auth_headers(@agent)
    assert_response :ok
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF")
  end

  test "the invoice PDF and receipt list are available (AC-67 / AC-105)" do
    @rental.update!(status: "completed")
    get "/api/#{@org.slug}/receipts", headers: auth_headers(@agent)
    assert_response :ok
    assert response.parsed_body["data"].any?

    get "/api/#{@org.slug}/receipts/#{@rental.id}/invoice", headers: auth_headers(@agent)
    assert_response :ok
    assert_equal "application/pdf", response.media_type
  end

  test "counter agents can look a rental up by plate (AC-90)" do
    get "/api/#{@org.slug}/counter/lookup",
        params: { q: @graph[:vehicle].license_plate }, headers: auth_headers(@agent)
    assert_response :ok
    assert_equal @rental.reservation_number, response.parsed_body["data"].first["reservation_number"]
  end

  test "customers cannot settle a deposit (AC-94)" do
    customer_role = create_role(slug: "customer")
    grant(@org, customer_role, "rentals.index", "rentals.show")
    customer = member_of(@org, role_slug: "customer", role: customer_role,
                               email: "settle-customer@example.com")

    post "/api/#{@org.slug}/payments/settle",
         params: { rental_id: @rental.id }.to_json,
         headers: json_headers.merge(auth_headers(customer))

    assert_response :forbidden
  end

  test "the inspection comparison pairs departure and return evidence (AC-51)" do
    Inspection.create!(organization: @org, rental: @rental, vehicle: @graph[:vehicle],
                       inspection_type: "check_out", odometer_reading: 10_000,
                       fuel_percentage: 100, status: "completed")

    get "/api/#{@org.slug}/rentals/#{@rental.id}/inspection_comparison", headers: auth_headers(@agent)
    assert_response :ok
    body = response.parsed_body
    assert_equal 700, body.dig("deltas", "odometer_delta")
    assert_equal 50, body.dig("deltas", "fuel_variance_percentage")
  end
end
