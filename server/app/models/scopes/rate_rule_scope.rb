# frozen_string_literal: true

module Scopes
  # Retail customers and guests only ever see active rate rules; staff see the
  # full pricing history (including retired rules) in /admin/rates.
  class RateRuleScope < Rhino::ResourceScope
    def apply(relation)
      return relation if user.present? && %w[fleet_manager counter_agent].include?(role)

      relation.where(is_active: true)
    end
  end
end
