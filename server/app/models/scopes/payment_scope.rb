# frozen_string_literal: true

module Scopes
  # Customers only see payments attached to their own customer profile.
  class PaymentScope < Rhino::ResourceScope
    def apply(relation)
      return relation unless role == 'customer'

      profile_ids = user.customer_profiles.where(organization_id: organization.id).pluck(:id)
      relation.where(customer_profile_id: profile_ids)
    end
  end
end
