# frozen_string_literal: true

# Authorization for the `inspections` resource.
class InspectionPolicy < Rhino::ResourcePolicy
  self.resource_slug = 'inspections'

  def permitted_attributes_for_show(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return ['*'] if has_role?(user, 'counter_agent')
    return [
      'id',
      'rental_id',
      'vehicle_id',
      'inspection_type',
      'odometer_reading',
      'fuel_percentage',
      'cleanliness_status',
      'customer_signature_timestamp',
      'performed_at',
      'type_label',
      'odometer',
      'fuel',
      'damage_count',
      'new_damage_count',
      'photo_count',
      'signed',
      'required_photo_angles'
    ] if has_role?(user, 'customer')
    []
  end

  def hidden_attributes_for_show(_user)
    []
  end

  def permitted_attributes_for_create(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return [
      'rental_id',
      'vehicle_id',
      'user_id',
      'inspection_type',
      'odometer_reading',
      'fuel_percentage',
      'cleanliness_status',
      'customer_signature_url',
      'customer_signature_timestamp',
      'notes',
      'performed_at',
      'status'
    ] if has_role?(user, 'counter_agent')
    return [] if has_role?(user, 'customer')
    []
  end

  def permitted_attributes_for_update(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return [
      'odometer_reading',
      'fuel_percentage',
      'cleanliness_status',
      'customer_signature_url',
      'customer_signature_timestamp',
      'notes',
      'performed_at',
      'status'
    ] if has_role?(user, 'counter_agent')
    return [] if has_role?(user, 'customer')
    []
  end
end
