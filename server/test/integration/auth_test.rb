# frozen_string_literal: true

require "test_helper"

# AC-22 / AC-25 / AC-113 / AC-126 — authentication over the real HTTP API.
class AuthTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization(slug: "auth-org")
    @role = create_role(slug: "customer")
    crud!(@org, @role, "customer_profiles")
    @user = member_of(@org, role_slug: "customer", role: @role, email: "auth-#{SecureRandom.hex(3)}@example.com")
  end

  def json_headers(extra = {})
    { "Content-Type" => "application/json" }.merge(extra)
  end

  test "valid credentials return a bearer token and the organization slug (AC-22)" do
    post "/api/auth/login",
         params: { email: @user.email, password: "password" }.to_json,
         headers: json_headers

    assert_response :ok
    body = response.parsed_body
    assert body["token"].present?
    assert_equal @org.slug, body["organization_slug"]
    assert_equal body["token"], @user.reload.api_token
  end

  test "invalid credentials never reveal whether the account exists (AC-25)" do
    post "/api/auth/login",
         params: { email: @user.email, password: "wrong" }.to_json, headers: json_headers
    assert_response :unauthorized

    post "/api/auth/login",
         params: { email: "nobody-#{SecureRandom.hex(3)}@example.com", password: "wrong" }.to_json,
         headers: json_headers
    assert_response :unauthorized
    assert_equal "Invalid credentials", response.parsed_body["message"]
  end

  test "logout revokes the token" do
    @user.regenerate_api_token
    token = @user.api_token
    post "/api/auth/logout", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :ok
    assert_not_equal token, @user.reload.api_token

    get "/api/#{@org.slug}/customer_profiles", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :unauthorized
  end

  test "protected endpoints require a token" do
    get "/api/#{@org.slug}/customer_profiles"
    assert_response :unauthorized
    assert_equal "Unauthenticated.", response.parsed_body["message"]
  end

  test "open customer registration creates an unapproved account (AC-126)" do
    email = "signup-#{SecureRandom.hex(4)}@example.com"
    post "/api/auth/register",
         params: { name: "New Renter", email: email, password: "password",
                   password_confirmation: "password", organization_slug: @org.slug }.to_json,
         headers: json_headers

    assert_response :created
    user = User.find_by(email: email)
    assert_not_nil user
    assert_equal false, user.approved
    assert user.verification_token.present?
    assert_match(/verify/i, response.parsed_body["message"])
  end

  test "registration is rejected with a duplicate email" do
    post "/api/auth/register",
         params: { name: "Dup", email: @user.email, password: "password",
                   password_confirmation: "password", organization_slug: @org.slug }.to_json,
         headers: json_headers
    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].key?("email")
  end

  test "email verification approves the account (AC-113)" do
    email = "verify-#{SecureRandom.hex(4)}@example.com"
    post "/api/auth/register",
         params: { name: "Verify Me", email: email, password: "password",
                   password_confirmation: "password", organization_slug: @org.slug }.to_json,
         headers: json_headers
    token = response.parsed_body["verification_token"]

    post "/api/registrations/verify", params: { token: token }.to_json, headers: json_headers
    assert_response :ok
    assert User.find_by(email: email).approved
  end

  test "an invitation token still registers staff through the same endpoint (AC-113)" do
    manager = create_role(slug: "fleet_manager")
    invitation = Rhino::OrganizationInvitation.create!(
      organization: @org, role: manager,
      email: "invited-#{SecureRandom.hex(3)}@example.com",
      token: SecureRandom.hex(32)
    )

    post "/api/auth/register",
         params: { token: invitation.token, name: "Invited", email: invitation.email,
                   password: "password", password_confirmation: "password" }.to_json,
         headers: json_headers

    assert_response :created
    user = User.find_by(email: invitation.email)
    assert_not_nil user
    assert user.user_roles.exists?(organization_id: @org.id)
    assert_equal "accepted", invitation.reload.status
  end
end
