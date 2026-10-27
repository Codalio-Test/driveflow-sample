# frozen_string_literal: true

# Authorization for the `vehicle_categories` resource.
class VehicleCategoryPolicy < Rhino::ResourcePolicy
  self.resource_slug = 'vehicle_categories'

  def permitted_attributes_for_show(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return ['*'] if has_role?(user, 'counter_agent')
    return [
      'id',
      'name',
      'code',
      'description',
      'base_daily_rate',
      'security_deposit_amount',
      'mileage_allowance_per_day',
      'excess_mileage_rate',
      'passenger_capacity',
      'baggage_capacity',
      'transmission',
      'rate',
      'vehicles',
      'vehicle_count',
      'available_vehicle_count'
    ] if has_role?(user, 'customer')
    []
  end

  def hidden_attributes_for_show(_user)
    []
  end

  def permitted_attributes_for_create(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return [] if has_role?(user, 'counter_agent')
    return [] if has_role?(user, 'customer')
    []
  end

  def permitted_attributes_for_update(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return [] if has_role?(user, 'counter_agent')
    return [] if has_role?(user, 'customer')
    []
  end
end
