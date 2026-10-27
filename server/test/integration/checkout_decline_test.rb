# frozen_string_literal: true

require "test_helper"

# AC-16 — a declined card (or an invalid card) at /booking/checkout must surface
# the *specific* decline reason and must not discard the renter details the
# customer already typed, nor commit the reservation.
#
# The prototype ships a plain card block (swapped for Stripe Elements on the
# client), so the server contract this test pins is:
#   * POST /api/{org}/bookings/confirm with a declining payment method returns
#     422 carrying `message` + `code` (the reason the UI renders inline),
#   * no Payment row is written and the rental stays `reserved` (so the form can
#     be resubmitted without re-entering anything),
#   * the renter's name/email ARE persisted on the customer profile before the
#     authorization is attempted, so a retry keeps the previously entered fields.
class CheckoutDeclineTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization(slug: "checkout-decline-org")
    @graph = build_rental_graph(organization: @org)
  end

  def json_headers
    { "Content-Type" => "application/json" }
  end

  # Creates a draft reservation through the public funnel and returns its id.
  def draft_booking(email: "decline-#{SecureRandom.hex(4)}@example.com")
    post "/api/#{@org.slug}/bookings",
         params: { vehicle_category_id: @graph[:category].id, location_id: @graph[:location].id,
                   full_name: "Dana Declined", email: email, phone_number: "+1-415-555-0123",
                   pickup_datetime: 2.days.from_now.iso8601,
                   scheduled_return_datetime: 5.days.from_now.iso8601,
                   protection_tier: "standard" }.to_json,
         headers: json_headers
    assert_response :created
    response.parsed_body["rental"]["id"]
  end

  # AC-16: a card that declines mid-confirm returns the concrete reason and
  # rolls the reservation back to `reserved`, leaving the form usable.
  test "a declined card surfaces the specific reason and keeps the renter's details (AC-16)" do
    rental_id = draft_booking

    post "/api/#{@org.slug}/bookings/confirm",
         params: { rental_id: rental_id, full_name: "Dana Declined",
                   email: "dana.declined@example.com", payment_method_last4: "0341" }.to_json,
         headers: json_headers

    assert_response :unprocessable_entity
    body = response.parsed_body
    # The decline reason the checkout screen renders next to the card widget.
    assert_equal "card_declined", body["code"]
    assert_equal "Your card was declined.", body["message"]
    assert body.dig("errors", "payment").present?

    # Nothing was charged and the reservation was not committed.
    rental = Rental.find(rental_id)
    assert_equal "reserved", rental.status
    assert_equal 0, rental.payments.count

    # The renter details already typed into the form survive the failure, so a
    # retry does not clear the fields (AC-16 "without clearing previously
    # entered form fields").
    assert_equal "Dana Declined", rental.customer_profile.reload.full_name
    assert_equal "dana.declined@example.com", rental.customer_profile.email
  end

  # AC-16: an insufficient-funds decline is reported distinctly from a generic
  # decline so the renter sees the actual reason.
  test "an insufficient-funds decline reports its own reason (AC-16)" do
    rental_id = draft_booking

    post "/api/#{@org.slug}/bookings/confirm",
         params: { rental_id: rental_id, stripe_payment_method: "pm_card_insufficient_funds" }.to_json,
         headers: json_headers

    assert_response :unprocessable_entity
    assert_equal "card_declined", response.parsed_body["code"]
    assert_equal "Your card has insufficient funds.", response.parsed_body["message"]
    assert_equal "reserved", Rental.find(rental_id).status
  end

  # AC-16 (happy counterpart): a valid card confirms the same reservation, which
  # proves the failure above was the card and not the payload.
  test "the same booking confirms with a valid card (AC-16)" do
    rental_id = draft_booking

    post "/api/#{@org.slug}/bookings/confirm",
         params: { rental_id: rental_id, payment_method_last4: "4242" }.to_json,
         headers: json_headers

    assert_response :created
    rental = Rental.find(rental_id)
    assert_equal "confirmed", rental.status
    assert_equal 1, rental.payments.where(transaction_type: "rental_payment", status: "succeeded").count
  end

  # AC-16 / AC-13 (edge): confirming an unknown reservation is a 404, never a
  # silent success — the checkout page must be able to show an error state.
  test "confirming an unknown reservation is a 404 (AC-16)" do
    post "/api/#{@org.slug}/bookings/confirm",
         params: { rental_id: 0, payment_method_last4: "4242" }.to_json,
         headers: json_headers

    assert_response :not_found
  end
end
