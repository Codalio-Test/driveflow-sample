# frozen_string_literal: true

require "test_helper"

# AC-7 / AC-32 / AC-33 / AC-126 — the User identity model.
class UserTest < ActiveSupport::TestCase
  test "approved flag is persisted and drives account state (AC-7 / AC-126)" do
    user = create_user(email: "approval-#{SecureRandom.hex(3)}@example.com", approved: false)
    assert_equal false, user.approved
    user.verify_email!
    assert user.reload.approved
    assert user.verified?
  end

  test "first and last name are persisted (AC-32 / AC-33)" do
    user = create_user(email: "name-#{SecureRandom.hex(3)}@example.com")
    user.update!(first_name: "David", last_name: "Chen")
    assert_equal "David", user.reload.first_name
    assert_equal "Chen", user.last_name
    assert_equal "David Chen", user.display_name
  end

  test "name is derived from first/last name when omitted" do
    user = User.new(email: "derived-#{SecureRandom.hex(3)}@example.com", password: "password",
                    first_name: "Ada", last_name: "Lovelace", approved: true)
    user.valid?
    assert_equal "Ada Lovelace", user.name
  end

  test "email must be unique and well formed" do
    email = "unique-#{SecureRandom.hex(3)}@example.com"
    create_user(email: email)
    duplicate = User.new(email: email, name: "Dup", password: "password", approved: true)
    assert_not duplicate.valid?
    assert_not User.new(email: "not-an-email", name: "x", password: "password", approved: true).valid?
  end

  test "an api token is issued for Bearer auth" do
    user = create_user(email: "token-#{SecureRandom.hex(3)}@example.com")
    assert user.api_token.present?
    old = user.api_token
    user.regenerate_api_token
    assert_not_equal old, user.api_token
  end

  test "credentials are hidden from API responses" do
    user = create_user(email: "hidden-#{SecureRandom.hex(3)}@example.com")
    payload = user.as_rhino_json
    assert_not payload.key?("password_digest")
    assert_not payload.key?("api_token")
    assert_not payload.key?("verification_token")
  end

  test "verification token lifecycle" do
    user = create_user(email: "verify-#{SecureRandom.hex(3)}@example.com", approved: false)
    token = user.issue_verification_token!
    assert token.present?
    assert_equal token, user.reload.verification_token
    user.verify_email!
    assert_nil user.reload.verification_token
    assert user.email_verified_at.present?
  end
end
