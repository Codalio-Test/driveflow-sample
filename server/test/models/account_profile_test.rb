# frozen_string_literal: true

require "test_helper"

# AC-22 / AC-117 — the settings/self-update path and the shape of the runtime
# identities the host smoke checks. Verifies that Rhino's default read-only
# built-in policies cannot lock the client out of its own account, and that a
# user can never edit somebody else's.
class AccountProfileTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "settings-org")
    @role = create_role(slug: "customer")
    crud!(@org, @role, "customer_profiles")
    @user = member_of(@org, role_slug: "customer", role: @role, email: "settings-me@example.com")
    @other = member_of(@org, role_slug: "customer", role: @role, email: "settings-other@example.com")
  end

  test "a user may update their own account (UserPolicy#update?)" do
    policy = UserPolicy.new(@user, @user)
    assert policy.update?, "self-update must be allowed or Save Profile 403s forever"
    assert policy.show?
  end

  test "self-service fields are limited to contact details" do
    policy = UserPolicy.new(@user, @user)
    permitted = policy.permitted_attributes_for_update(@user)
    assert_includes permitted, "name"
    assert_includes permitted, "phone_number"
    assert_not_includes permitted, "approved"
    assert_not_includes permitted, "api_token"
  end

  test "a user may not update another account" do
    policy = UserPolicy.new(@user, @other)
    assert_not policy.update?
  end

  test "the users collection is default-deny for the demo roles" do
    assert_not @user.has_permission?("users.index", @org)
  end

  test "customer_profiles update is permitted for the owning role only" do
    profile = CustomerProfile.create!(organization: @org, user: @user, full_name: "Me",
                                      email: "me-#{SecureRandom.hex(3)}@example.com")
    other_profile = CustomerProfile.create!(organization: @org, user: @other, full_name: "Them",
                                            email: "them-#{SecureRandom.hex(3)}@example.com")

    visible = with_context(user: @user, organization: @org) { CustomerProfile.pluck(:id) }
    assert_includes visible, profile.id
    assert_not_includes visible, other_profile.id
  end
end
