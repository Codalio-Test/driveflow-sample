# frozen_string_literal: true

# Authorization for the `vehicle_maintenance_logs` resource.
class VehicleMaintenanceLogPolicy < Rhino::ResourcePolicy
  self.resource_slug = 'vehicle_maintenance_logs'

  def permitted_attributes_for_show(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return ['*'] if has_role?(user, 'counter_agent')
    return [
      'id',
      'vehicle_id',
      'service_type',
      'service_date',
      'status',
      'vehicle',
      'plate',
      'service',
      'progress',
      'detail',
      'priority',
      'status_label'
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
