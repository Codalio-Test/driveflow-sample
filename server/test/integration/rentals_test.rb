# frozen_string_literal: true

require "test_helper"

# AC-29 / AC-32 / AC-33 / AC-41 / AC-42 / AC-43 / AC-44 / AC-50 / AC-54 /
# AC-59 / AC-82 / AC-89 / AC-90 — rental CRUD per role and the agreement flow.
class RentalsTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization(slug: "rentals-org")
    @manager_role = create_role(slug: "fleet_manager")
    @counter_role = create_role(slug: "counter_agent")
    @customer_role = create_role(slug: "customer")

    crud!(@org, @manager_role, "rentals", "inspections", "vehicles", "rental_charges")
    grant(@org, @manager_role, "counter.departures", "counter.returns", "counter.lookup")
    grant(@org, @counter_role, "rentals.index", "rentals.show", "rentals.store", "rentals.update",
          "inspections.index", "inspections.show", "inspections.store", "inspections.update",
          "agreements.show", "agreements.sign", "agreements.complete_handover",
          "counter.departures", "counter.returns", "counter.lookup",
          "vehicles.index", "vehicles.show")
    grant(@org, @customer_role, "rentals.index", "rentals.show", "rentals.store", "rentals.update")

    @manager = member_of(@org, role_slug: "fleet_manager", role: @manager_role,
                               email: "rentals-manager@example.com")
    @counter = member_of(@org, role_slug: "counter_agent", role: @counter_role,
                               email: "rentals-counter@example.com")
    @customer = member_of(@org, role_slug: "customer", role: @customer_role,
                                email: "rentals-customer@example.com")
    @graph = build_rental_graph(organization: @org)
    @graph[:profile].update!(user: @customer)
    @rental = @graph[:rental]
  end

  def json_headers
    { "Content-Type" => "application/json" }
  end

  test "only counter staff and managers may read the counter queues (AC-29)" do
    [@counter, @manager].each do |user|
      get "/api/#{@org.slug}/counter/departures", headers: auth_headers(user)
      assert_response :ok
    end

    get "/api/#{@org.slug}/counter/departures", headers: auth_headers(@customer)
    assert_response :forbidden
  end

  test "a counter agent can create and update a rental (AC-32 / AC-33)" do
    post "/api/#{@org.slug}/rentals",
         params: { customer_profile_id: @graph[:profile].id,
                   vehicle_category_id: @graph[:category].id,
                   location_id: @graph[:location].id,
                   reservation_number: "DF-RT-#{SecureRandom.hex(3)}",
                   pickup_datetime: 1.day.from_now.iso8601,
                   scheduled_return_datetime: 4.days.from_now.iso8601,
                   scheduled_duration_days: 3, status: "confirmed" }.to_json,
         headers: json_headers.merge(auth_headers(@counter))

    assert_response :created
    created = Rental.find(response.parsed_body["id"])
    assert_equal "confirmed", created.status

    put "/api/#{@org.slug}/rentals/#{created.id}",
        params: { status: "active" }.to_json,
        headers: json_headers.merge(auth_headers(@counter))
    assert_response :ok
    assert_equal "active", created.reload.status
  end

  test "a customer can update their own reservation configuration but not staff-only fields (AC-33)" do
    put "/api/#{@org.slug}/rentals/#{@rental.id}",
        params: { protection_tier: "full" }.to_json,
        headers: json_headers.merge(auth_headers(@customer))
    assert_response :ok
    assert_equal "full", @rental.reload.protection_tier

    put "/api/#{@org.slug}/rentals/#{@rental.id}",
        params: { total_paid_amount: 0 }.to_json,
        headers: json_headers.merge(auth_headers(@customer))
    assert_response :forbidden
  end

  test "the agreement payload itemizes rates, deposit and condition (AC-41)" do
    get "/api/#{@org.slug}/agreements", params: { rental_id: @rental.id }, headers: auth_headers(@counter)
    assert_response :ok
    agreement = response.parsed_body["agreement"]
    assert_equal @rental.reservation_number, agreement["reservation_number"]
    assert agreement["renter"].present?
    assert agreement["rates"].present?
    assert agreement["deposit"].present?
    assert agreement["condition_summary"].present?
    assert_equal 60, agreement.dig("late_policy", "grace_minutes")
    assert_equal 100.0, agreement.dig("late_policy", "daily_cap")
  end

  test "signing captures the signature timestamp and url (AC-42 / AC-45)" do
    @rental.inspections.create!(organization: @org, vehicle: @graph[:vehicle],
                                inspection_type: "check_out", odometer_reading: 9_800,
                                fuel_percentage: 100, status: "completed")
    signature = "data:image/png;base64,#{Base64.strict_encode64(File.binread(Rails.root.join('test/fixtures/files/sample.png')))}"
    post "/api/#{@org.slug}/agreements/sign",
         params: { rental_id: @rental.id, signed_by_name: "David Chen",
                   signature_data_url: signature }.to_json,
         headers: json_headers.merge(auth_headers(@counter))

    assert_response :created
    assert @rental.reload.agreement_signed_at.present?
    assert_equal "David Chen", @rental.agreement_signed_by_name
    assert_equal signature, @rental.inspections.kept.find_by(inspection_type: "check_out").customer_signature_url
  end

  test "completing handover activates the rental and rents the vehicle (AC-43)" do
    @rental.inspections.create!(organization: @org, vehicle: @graph[:vehicle],
                                inspection_type: "check_out", odometer_reading: 9_800,
                                fuel_percentage: 100, status: "completed")

    post "/api/#{@org.slug}/rentals/#{@rental.id}/finalize",
         params: { customer_signature_url: "https://example.com/sig.png",
                   signed_by_name: "David Chen" }.to_json,
         headers: json_headers.merge(auth_headers(@counter))

    assert_response :ok
    assert_equal "active", @rental.reload.status
    assert_equal "rented", @graph[:vehicle].reload.status
  end

  test "a customer cannot reach the agreement surface (AC-44)" do
    get "/api/#{@org.slug}/agreements", params: { rental_id: @rental.id },
        headers: auth_headers(@customer)
    assert_response :forbidden
  end

  test "a customer cannot run a tablet inspection (AC-50 / AC-54)" do
    post "/api/#{@org.slug}/inspections",
         params: { rental_id: @rental.id, vehicle_id: @graph[:vehicle].id,
                   inspection_type: "check_out", odometer_reading: 1, fuel_percentage: 1 }.to_json,
         headers: json_headers.merge(auth_headers(@customer))
    assert_response :forbidden
  end

  test "a customer cannot settle a deposit (AC-59)" do
    post "/api/#{@org.slug}/payments/settle",
         params: { rental_id: @rental.id }.to_json,
         headers: json_headers.merge(auth_headers(@customer))
    assert_response :forbidden
  end

  test "extension is manager-only (AC-84 / AC-89)" do
    post "/api/#{@org.slug}/rentals/#{@rental.id}/extend",
         params: { scheduled_return_datetime: 3.days.from_now.iso8601 }.to_json,
         headers: json_headers.merge(auth_headers(@customer))
    assert_response :forbidden
  end

  test "the overdue sweeper flips live contracts once the grace expires (AC-82)" do
    @rental.update!(status: "active", scheduled_return_datetime: 2.hours.ago)
    RentalOverdueSweeperJob.perform_now

    get "/api/#{@org.slug}/rentals", params: { filter: { status: "overdue" } },
        headers: auth_headers(@manager)
    assert_response :ok
    assert_includes response.parsed_body["data"].map { |r| r["id"] }, @rental.id
  end

  test "an unauthenticated rentals request is rejected" do
    get "/api/#{@org.slug}/rentals"
    assert_response :unauthorized
  end

  test "a bad payload returns field errors, not a crash (AC-4 / AC-125)" do
    post "/api/#{@org.slug}/rentals",
         params: { status: "not_a_status" }.to_json,
         headers: json_headers.merge(auth_headers(@manager))

    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].present?
  end
end
