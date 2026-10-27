# frozen_string_literal: true

# Authorization for the `damage_records` resource.
class DamageRecordPolicy < Rhino::ResourcePolicy
  self.resource_slug = 'damage_records'

  def permitted_attributes_for_show(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return ['*'] if has_role?(user, 'counter_agent')
    return [
      'id',
      'vehicle_id',
      'panel_location',
      'severity',
      'description',
      'photo_url',
      'is_pre_existing',
      'label',
      'new_damage',
      'photo',
      'cost'
    ] if has_role?(user, 'customer')
    []
  end

  def hidden_attributes_for_show(_user)
    []
  end

  def permitted_attributes_for_create(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return [
      'inspection_id',
      'vehicle_id',
      'panel_location',
      'severity',
      'description',
      'photo_url',
      'is_pre_existing',
      'repair_cost_estimate',
      'repaired',
      'photo_taken_at',
      'captured_angle',
      'dimensions'
    ] if has_role?(user, 'counter_agent')
    return [] if has_role?(user, 'customer')
    []
  end

  def permitted_attributes_for_update(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return [
      'panel_location',
      'severity',
      'description',
      'photo_url',
      'is_pre_existing',
      'repair_cost_estimate',
      'repaired',
      'photo_taken_at',
      'captured_angle',
      'dimensions'
    ] if has_role?(user, 'counter_agent')
    return [] if has_role?(user, 'customer')
    []
  end
end
