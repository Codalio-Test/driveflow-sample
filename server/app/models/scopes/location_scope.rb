# frozen_string_literal: true

module Scopes
  # Locations are readable by every role. Inactive branches are hidden from
  # guests and retail customers; staff manage the full branch list.
  class LocationScope < Rhino::ResourceScope
    def apply(relation)
      return relation if user.present? && %w[fleet_manager counter_agent].include?(role)

      relation.where(is_active: true)
    end
  end
end
