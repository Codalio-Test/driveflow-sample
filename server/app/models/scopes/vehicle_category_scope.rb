# frozen_string_literal: true

module Scopes
  # Every role may browse the vehicle class catalogue; staff additionally see
  # classes whose vehicles are all out of service. No row-level restriction is
  # needed here — tenancy is enforced by BelongsToOrganization.
  class VehicleCategoryScope < Rhino::ResourceScope
    def apply(relation)
      relation
    end
  end
end
