# frozen_string_literal: true

# Policy for the User model.
#
# Required for Rhino's per-include authorization: when a resource exposes a
# User relation (e.g. ?include=assigned_to), Pundit looks up UserPolicy. It is
# also what makes the settings/self-update path
# (PATCH /api/{org}/users/:id) work: Rhino's stock built-in user policy is
# read-only, so without an override the form would 403 forever.
#
# Method signatures follow Rhino::ResourcePolicy (Pundit): the gate methods take
# NO arguments — the authenticated user and the record are available as `user`
# and `record`.
class UserPolicy < Rhino::ResourcePolicy
  self.resource_slug = 'users'

  def show?
    return true if own_record?

    super
  end

  def update?
    return true if own_record?

    super
  end

  # Self-service may only touch the caller's own contact details; memberships,
  # approval state and tokens stay server-controlled.
  def permitted_attributes_for_update(_user)
    return %w[name first_name last_name email phone_number] if own_record?

    %w[]
  end

  def permitted_attributes_for_create(_user)
    %w[]
  end

  private

  def own_record?
    user.present? && record.respond_to?(:id) && record.id == user.id
  end
end
