# frozen_string_literal: true

module Api
  # Bulk fleet operations that are not CRUD-shaped: apply one change set to many
  # vehicles in a single request, reporting per-vehicle results so the UI can
  # surface partial failures (AdminFleet bulk action bar).
  class VehiclesController < BaseController
    before_action :authorize_vehicles!

    # POST /api/:organization/vehicles/bulk
    #   { ids: [1,2], changes: { status: "cleaning" } }
    def bulk
      ids = Array(params[:ids]).map(&:to_i).uniq
      changes = normalize_changes(params[:changes] || params[:attributes] || {})

      return render(json: { errors: { ids: ['is required'] } }, status: :unprocessable_entity) if ids.empty?
      return render(json: { errors: { changes: ['is required'] } }, status: :unprocessable_entity) if changes.empty?

      results = []
      ActiveRecord::Base.transaction do
        vehicles = scoped(Vehicle).where(id: ids)
        found = vehicles.pluck(:id)

        vehicles.each do |vehicle|
          vehicle.assign_attributes(changes)
          if vehicle.save
            results << { id: vehicle.id, updated: true }
          else
            results << { id: vehicle.id, updated: false, errors: vehicle.errors.to_hash }
          end
        end

        (ids - found).each { |missing| results << { id: missing, updated: false, errors: { base: ['not found'] } } }
      end

      updated = results.count { |r| r[:updated] }
      render json: {
        message: "#{updated} of #{ids.size} vehicles updated",
        updated_count: updated,
        results: results
      }, status: updated.zero? ? :unprocessable_entity : :ok
    end

    private

    # Only writable operational columns may be bulk-edited.
    def normalize_changes(raw)
      allowed = %w[status location_id fuel_percentage current_odometer
                   vehicle_category_id color registration_expires_on]
      hash = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h
      hash.slice(*allowed).symbolize_keys
    end

    def authorize_vehicles!
      return true if permitted?('vehicles', 'update') || permitted?('vehicles', 'store')

      render json: { message: 'This action is unauthorized.' }, status: :forbidden
      false
    end
  end
end
