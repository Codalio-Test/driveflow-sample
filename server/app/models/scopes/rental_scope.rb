# frozen_string_literal: true

module Scopes
  # Row-level visibility for rentals: the `customer` role only ever sees its
  # own rental contracts; staff roles see the whole organization.
  class RentalScope < Rhino::ResourceScope
    # NOTE: no `relation.none` when the request context is missing. Outside a
    # request (seeds, jobs, console) the role cannot resolve, so narrowing here
    # would make every lookup return nothing and break idempotency. The tenant
    # boundary is enforced by BelongsToOrganization + Rhino.query; this scope
    # only narrows a resolved `customer` request.
    def apply(relation)
      return relation unless role == 'customer'

      profile_ids = user.customer_profiles.where(organization_id: organization.id).pluck(:id)
      relation.where(customer_profile_id: profile_ids)
    end
  end
end
