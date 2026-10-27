# frozen_string_literal: true

module Scopes
  # Vehicles whose odometer is within the service window of their next
  # scheduled service interval. Wired through `rhino_scopes service_due:` and
  # selected by the client with `?scope=serviceDue`.
  #
  # NOTE: deliberately NOT named `VehicleScope` — that exact name is
  # auto-applied to every Vehicle query by HasAutoScope.
  class VehicleServiceDueScope < Rhino::ResourceScope
    THRESHOLD_MILES = 500

    def apply(relation)
      relation.where(
        'COALESCE(vehicles.last_service_odometer, 0) + COALESCE(vehicles.service_interval_miles, 5000) - COALESCE(vehicles.current_odometer, 0) <= ?',
        THRESHOLD_MILES
      )
    end
  end
end
