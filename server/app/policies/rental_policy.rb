# frozen_string_literal: true

# Authorization for the `rentals` resource.
class RentalPolicy < Rhino::ResourcePolicy
  self.resource_slug = 'rentals'

  def permitted_attributes_for_show(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return ['*'] if has_role?(user, 'counter_agent')
    return [
      'id',
      'vehicle_category_id',
      'vehicle_id',
      'location_id',
      'reservation_number',
      'pickup_datetime',
      'scheduled_return_datetime',
      'actual_return_datetime',
      'scheduled_duration_days',
      'status',
      'protection_tier',
      'total_charges_amount',
      'total_paid_amount',
      'balance_owed_amount',
      'dropoff_location_code',
      'customer',
      'vehicle',
      'category',
      'due',
      'time',
      'dates',
      'accrued',
      'late_fee_accrued',
      'late_fee_capped',
      'late_hourly_rate',
      'late_grace_minutes',
      'grace_expires_at',
      'billable_overdue_hours',
      'overdue_duration',
      'overdue',
      'daily_cap',
      'balance',
      'deposit_status',
      'qr_code_url',
      'reference'
    ] if has_role?(user, 'customer')
    []
  end

  def hidden_attributes_for_show(_user)
    []
  end

  def permitted_attributes_for_create(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return [
      'customer_profile_id',
      'vehicle_category_id',
      'vehicle_id',
      'location_id',
      'reservation_number',
      'pickup_datetime',
      'scheduled_return_datetime',
      'scheduled_duration_days',
      'status',
      'protection_tier',
      'initial_odometer',
      'initial_fuel_percentage',
      'dropoff_location_code',
      'notes'
    ] if has_role?(user, 'counter_agent')
    return [
      'vehicle_category_id',
      'location_id',
      'pickup_datetime',
      'scheduled_return_datetime',
      'scheduled_duration_days',
      'protection_tier',
      'dropoff_location_code'
    ] if has_role?(user, 'customer')
    []
  end

  def permitted_attributes_for_update(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return [
      'vehicle_id',
      'location_id',
      'scheduled_return_datetime',
      'actual_return_datetime',
      'status',
      'initial_odometer',
      'final_odometer',
      'initial_fuel_percentage',
      'final_fuel_percentage',
      'total_charges_amount',
      'total_paid_amount',
      'balance_owed_amount',
      'dropoff_location_code',
      'protection_tier',
      'notes',
      'agreement_signed_at',
      'agreement_signed_by_name',
      'escalated_for_recovery'
    ] if has_role?(user, 'counter_agent')
    return [
      'protection_tier',
      'location_id',
      'pickup_datetime',
      'scheduled_return_datetime',
      'scheduled_duration_days',
      'dropoff_location_code'
    ] if has_role?(user, 'customer')
    []
  end
end
