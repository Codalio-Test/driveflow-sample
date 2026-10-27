# frozen_string_literal: true

require "test_helper"

# AC-128 — the runtime seed contract. Seeds must create one Role row per key in
# `.rhino/blueprints/_roles.yaml` and a demo UsersRole membership for each role,
# so `useUserRole()` resolves and the per-role route gates work out of the box.
#
# This runs the real `db/seeds.rb` (inside the test transaction, so nothing is
# committed) and asserts both the role/membership contract and its idempotency.
class SeedsContractTest < ActiveSupport::TestCase
  SEED_PATH = Rails.root.join("db", "seeds.rb")

  def run_seeds
    # Quiet the seed's progress logging AND its constant-reassignment warning
    # (each `load` re-evaluates `SEED_PASSWORD`); only failures matter here.
    original_stdout = $stdout
    original_verbose = $VERBOSE
    $stdout = StringIO.new
    $VERBOSE = nil
    load SEED_PATH
  ensure
    $stdout = original_stdout
    $VERBOSE = original_verbose
  end

  # AC-128: every blueprint role exists and has a demo membership.
  test "seeds create one Role per _roles.yaml key with a demo membership each (AC-128)" do
    run_seeds

    roles_spec = YAML.load_file(Rails.root.join(".rhino", "blueprints", "_roles.yaml"))["roles"] || {}
    assert_equal %w[counter_agent customer fleet_manager], roles_spec.keys.sort,
                 "the blueprint roles file defines the three DriveFlow roles"

    roles_spec.each_key do |slug|
      role = Role.find_by(slug: slug)
      assert_not_nil role, "expected a Role row for #{slug}"
      assert UserRole.where(role: role).exists?,
             "expected a demo UsersRole membership so the #{slug} role resolves"
    end
  end

  # AC-128: the seeded runtime identities resolve their role for the demo
  # organization and carry the permissions the route gates depend on.
  test "the seeded identities resolve their role and permissions (AC-128)" do
    run_seeds

    org = Organization.find_by(slug: "demo-org")
    assert_not_nil org

    admin = User.find_by(email: "administrator@example.com")
    assert_not_nil admin
    assert_equal "fleet_manager", admin.role_slug_for_validation(org)
    assert admin.has_permission?("vehicle_categories.index", org)

    viewer = User.find_by(email: "viewer@example.com")
    assert_equal "customer", viewer.role_slug_for_validation(org)
    assert viewer.has_permission?("vehicle_categories.index", org)

    # Every seeded staff identity has at least one organization.
    %w[fleet_manager@demo.com counter_agent@demo.com customer@demo.com].each do |email|
      assert User.find_by(email: email).organizations.any?, "#{email} should have an organization"
    end
  end

  # AC-128: re-running the seed is safe — counts are stable, which is what makes
  # it usable as the runtime's startup hook.
  test "seeds are idempotent (AC-128)" do
    run_seeds
    snapshot = {
      roles: Role.count, memberships: UserRole.count, organizations: Organization.count,
      grants: OrgRolePermission.count, users: User.count
    }

    run_seeds

    assert_equal snapshot[:roles], Role.count
    assert_equal snapshot[:memberships], UserRole.count
    assert_equal snapshot[:organizations], Organization.count
    assert_equal snapshot[:grants], OrgRolePermission.count
    assert_equal snapshot[:users], User.count
  end

  # AC-128: the tenant-isolation identity the runtime smoke uses never becomes a
  # member of the demo organization.
  test "the outsider identity stays outside the demo organization (AC-128)" do
    run_seeds

    admin = User.find_by(email: "administrator@example.com")
    outsider = User.find_by(email: "outsider@example.com")
    other_org = Organization.find_by(slug: "runtime-other-org")

    assert outsider.user_roles.exists?(organization_id: other_org.id)
    assert_not admin.organizations.include?(other_org)
  end
end
