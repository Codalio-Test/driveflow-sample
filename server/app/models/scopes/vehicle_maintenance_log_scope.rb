# frozen_string_literal: true

module Scopes
  # Maintenance work orders are internal fleet records; retail customers and
  # guests never see them. Staff (counter agents and fleet managers) do.
  class VehicleMaintenanceLogScope < Rhino::ResourceScope
    def apply(relation)
      return relation unless role == 'customer'

      relation.none
    end
  end
end
