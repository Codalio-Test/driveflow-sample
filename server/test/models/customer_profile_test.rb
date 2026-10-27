# frozen_string_literal: true

require "test_helper"

# AC-6 / AC-18 / AC-19 / AC-20 / AC-31 / AC-123 — the CustomerProfile data model.
class CustomerProfileTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "profile-org")
    @graph = build_rental_graph(organization: @org)
    @profile = @graph[:profile]
  end

  test "date of birth is persisted (AC-6)" do
    @profile.update!(date_of_birth: Date.new(1988, 6, 14))
    assert_equal Date.new(1988, 6, 14), @profile.reload.date_of_birth
  end

  test "license state, expiry and country are persisted (AC-18 / AC-19 / AC-20)" do
    assert_equal "CA", @profile.license_state
    assert_not_nil @profile.license_expiry_date
    assert_equal "USA", @profile.license_country
  end

  test "an expired license is detected and blocks check-out (AC-31)" do
    @profile.update!(license_expiry_date: 1.day.ago.to_date)
    assert @profile.license_expired?
    assert_not @profile.license_valid?
  end

  test "a valid license is not flagged" do
    @profile.update!(license_expiry_date: 1.year.from_now.to_date)
    assert_not @profile.license_expired?
    assert @profile.license_valid?
  end

  test "full name and email are required" do
    incomplete = CustomerProfile.new(organization: @org)
    assert_not incomplete.valid?
    assert_includes incomplete.errors.attribute_names, :full_name
    assert_includes incomplete.errors.attribute_names, :email
  end

  test "a guest profile needs no user (AC-123)" do
    guest = CustomerProfile.create!(
      organization: @org, full_name: "Guest Renter", email: "guest-#{SecureRandom.hex(3)}@example.com"
    )
    assert guest.persisted?
    assert_nil guest.user_id
    assert guest.guest?
    assert guest.rhino_computed_attributes["guest"]
  end

  test "card details surface for the billing page (AC-67)" do
    attrs = @profile.rhino_computed_attributes
    assert_equal "4242", attrs["card_last4"]
    assert_equal "visa", attrs["card_brand"]
  end

  test "customers only see their own profile (AC-114)" do
    customer_role = create_role(slug: "customer")
    customer = create_user(email: "profile-customer@example.com")
    UserRole.create!(user: customer, organization: @org, role: customer_role)
    @profile.update!(user: customer)
    other = CustomerProfile.create!(organization: @org, full_name: "Other", email: "other-#{SecureRandom.hex(3)}@example.com")

    visible = with_context(user: customer, organization: @org) do
      CustomerProfile.pluck(:id)
    end
    assert_includes visible, @profile.id
    assert_not_includes visible, other.id
  end
end
