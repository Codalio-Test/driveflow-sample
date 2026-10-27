# frozen_string_literal: true

module Scopes
  # Auto-applied to every Vehicle query (HasAutoScope). Guests browsing the
  # public catalog must never see vehicles that are not rentable, and a
  # customer must not see decommissioned assets.
  class VehicleScope < Rhino::ResourceScope
    NON_RENTABLE = %w[maintenance cleaning].freeze

    def apply(relation)
      return relation if user.present? && %w[fleet_manager counter_agent].include?(role)

      relation.where.not(status: NON_RENTABLE)
    end
  end
end
