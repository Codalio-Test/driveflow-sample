# frozen_string_literal: true

module Scopes
  # Customers only see inspections for their own rentals.
  class InspectionScope < Rhino::ResourceScope
    def apply(relation)
      return relation unless role == 'customer'

      profile_ids = user.customer_profiles.where(organization_id: organization.id).pluck(:id)
      relation.joins(:rental).where(rentals: { customer_profile_id: profile_ids })
    end
  end
end
