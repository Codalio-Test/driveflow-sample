# frozen_string_literal: true

# Authorization for the `vehicles` resource.
class VehiclePolicy < Rhino::ResourcePolicy
  self.resource_slug = 'vehicles'

  def permitted_attributes_for_show(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return ['*'] if has_role?(user, 'counter_agent')
    return [
      'id',
      'vehicle_category_id',
      'location_id',
      'make',
      'model',
      'year',
      'color',
      'fuel_type',
      'status',
      'name',
      'plate',
      'location',
      'miles',
      'health',
      'service_due',
      'next_service_odometer',
      'miles_until_service',
      'service_progress',
      'service_label',
      'maintenance_active'
    ] if has_role?(user, 'customer')
    []
  end

  def hidden_attributes_for_show(_user)
    []
  end

  def permitted_attributes_for_create(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return [
      'vehicle_category_id',
      'location_id',
      'vin',
      'license_plate',
      'make',
      'model',
      'year',
      'color',
      'current_odometer',
      'fuel_percentage',
      'fuel_type',
      'status',
      'service_interval_miles',
      'last_service_odometer',
      'fuel_tank_capacity_gallons',
      'registration_expires_on'
    ] if has_role?(user, 'counter_agent')
    return [] if has_role?(user, 'customer')
    []
  end

  def permitted_attributes_for_update(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return [
      'location_id',
      'current_odometer',
      'fuel_percentage',
      'status'
    ] if has_role?(user, 'counter_agent')
    return [] if has_role?(user, 'customer')
    []
  end
end
