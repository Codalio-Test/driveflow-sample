# frozen_string_literal: true

module Api
  # The signed-in user's own identity for the current organization.
  #
  # The SPA needs three things the generated CRUD surface cannot answer on its
  # own: who am I, which organization am I acting in, and which roles do I hold
  # in it (for sidebar filtering and role gates). `/roles` alone is not enough —
  # the memberships live on `user_roles`, which the client cannot read without
  # knowing its own user id.
  class MeController < BaseController
    # GET /api/:organization/me
    def show
      memberships = current_user.user_roles.includes(:role).where(organization_id: current_organization.id)

      render json: {
        'user' => {
          'id' => current_user.id,
          'name' => current_user.display_name,
          'email' => current_user.email,
          'first_name' => current_user.first_name,
          'last_name' => current_user.last_name,
          'phone_number' => current_user.phone_number,
          'approved' => current_user.approved
        },
        'organization' => {
          'id' => current_organization.id,
          'name' => current_organization.name,
          'slug' => current_organization.slug
        },
        'roles' => memberships.map do |membership|
          {
            'id' => membership.role_id,
            'name' => membership.role&.name,
            'slug' => membership.role&.slug
          }
        end,
        'role_slugs' => memberships.map { |m| m.role&.slug }.compact,
        'customer_profile_id' => current_user.customer_profiles
                                                .where(organization_id: current_organization.id)
                                                .pick(:id)
      }
    end
  end
end
