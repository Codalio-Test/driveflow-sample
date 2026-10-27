# frozen_string_literal: true

module Scopes
  # Row-level visibility for damage records: the `customer` role only sees the
  # damage logged against its own rentals (via the inspection's rental).
  class DamageRecordScope < Rhino::ResourceScope
    def apply(relation)
      return relation unless role == 'customer'

      profile_ids = user.customer_profiles.where(organization_id: organization.id).pluck(:id)
      relation.joins(inspection: :rental).where(rentals: { customer_profile_id: profile_ids })
    end
  end
end
