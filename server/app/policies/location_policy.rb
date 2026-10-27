# frozen_string_literal: true

# Authorization for the `locations` resource.
class LocationPolicy < Rhino::ResourcePolicy
  self.resource_slug = 'locations'

  def permitted_attributes_for_show(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return [
      'id',
      'name',
      'code',
      'address',
      'city',
      'state',
      'postal_code',
      'is_active',
      'label',
      'vehicle_count'
    ] if has_role?(user, 'counter_agent')
    return [
      'id',
      'name',
      'code',
      'city',
      'state',
      'label',
      'vehicle_count'
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
