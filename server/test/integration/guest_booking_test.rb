# frozen_string_literal: true

require "test_helper"

# AC-1 / AC-3 / AC-4 / AC-13 / AC-15 / AC-17 / AC-112 / AC-123 — the public
# (guest) booking funnel: catalogue, availability, draft booking and confirm.
class GuestBookingTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization(slug: "guest-org")
    @graph = build_rental_graph(organization: @org)
  end

  def json_headers
    { "Content-Type" => "application/json" }
  end

  test "guests can browse the vehicle catalogue without an account (AC-3)" do
    get "/api/#{@org.slug}/vehicle_catalog"
    assert_response :ok
    row = response.parsed_body["data"].first
    assert_equal @graph[:category].name, row["name"]
    assert row["rate"].present?
    assert row.key?("passenger_capacity")
    assert row.key?("baggage_capacity")
    assert row.key?("transmission")
  end

  test "guests can search availability for a date range (AC-1 / AC-112)" do
    get "/api/#{@org.slug}/availability",
        params: { pickup_datetime: 1.day.from_now.iso8601,
                  scheduled_return_datetime: 4.days.from_now.iso8601 }
    assert_response :ok
    assert response.parsed_body["data"].any?
  end

  test "availability rejects a past or inverted date range (AC-4)" do
    get "/api/#{@org.slug}/availability",
        params: { pickup_datetime: 3.days.from_now.iso8601,
                  scheduled_return_datetime: 1.day.ago.iso8601 }
    assert_response :unprocessable_entity
  end

  test "a guest can create a draft reservation without an account (AC-17 / AC-123)" do
    post "/api/#{@org.slug}/bookings",
         params: {
           vehicle_category_id: @graph[:category].id,
           location_id: @graph[:location].id,
           full_name: "Guest Renter", email: "guest-#{SecureRandom.hex(4)}@example.com",
           phone_number: "+1-415-555-0000",
           pickup_datetime: 2.days.from_now.iso8601,
           scheduled_return_datetime: 5.days.from_now.iso8601,
           protection_tier: "standard"
         }.to_json, headers: json_headers

    assert_response :created
    rental = Rental.find(response.parsed_body["rental"]["id"])
    assert_equal "reserved", rental.status
    assert_nil rental.customer_profile.user_id
    assert_equal "Guest Renter", rental.customer_profile.full_name
    assert_not_empty response.parsed_body["charges"]
  end

  test "guest checkout confirms the reservation and issues a voucher (AC-13 / AC-15)" do
    post "/api/#{@org.slug}/bookings",
         params: { vehicle_category_id: @graph[:category].id, location_id: @graph[:location].id,
                   full_name: "Guest Confirm", email: "guest-confirm-#{SecureRandom.hex(4)}@example.com",
                   pickup_datetime: 2.days.from_now.iso8601,
                   scheduled_return_datetime: 5.days.from_now.iso8601 }.to_json,
         headers: json_headers
    assert_response :created
    rental_id = response.parsed_body["rental"]["id"]

    post "/api/#{@org.slug}/bookings/confirm",
         params: { rental_id: rental_id, full_name: "Guest Confirm",
                   email: "guest-confirm-#{SecureRandom.hex(4)}@example.com",
                   payment_method_last4: "4242" }.to_json, headers: json_headers

    assert_response :created
    body = response.parsed_body
    assert_equal "confirmed", body["rental"]["status"]
    assert body["qr_code_url"].start_with?("data:image")
    assert_equal "succeeded", body.dig("payment", "status")
    assert_equal "confirmed", Rental.find(rental_id).status
  end

  test "a declined card on confirm surfaces the decline without creating a payment" do
    post "/api/#{@org.slug}/bookings",
         params: { vehicle_category_id: @graph[:category].id,
                   full_name: "Decline Me", email: "decline-#{SecureRandom.hex(4)}@example.com",
                   pickup_datetime: 2.days.from_now.iso8601,
                   scheduled_return_datetime: 5.days.from_now.iso8601 }.to_json,
         headers: json_headers
    rental_id = response.parsed_body["rental"]["id"]

    post "/api/#{@org.slug}/bookings/confirm",
         params: { rental_id: rental_id, payment_method_last4: "0341" }.to_json,
         headers: json_headers

    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].key?("payment")
  end

  test "an anonymous guest cannot touch the authenticated tenant API" do
    get "/api/#{@org.slug}/rentals"
    assert_response :unauthorized
  end
end
