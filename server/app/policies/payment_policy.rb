# frozen_string_literal: true

# Authorization for the `payments` resource.
class PaymentPolicy < Rhino::ResourcePolicy
  self.resource_slug = 'payments'

  def permitted_attributes_for_show(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return ['*'] if has_role?(user, 'counter_agent')
    return [
      'id',
      'rental_id',
      'transaction_type',
      'amount',
      'status',
      'payment_method_last4',
      'processed_at',
      'rental',
      'type',
      'date',
      'last4',
      'reference',
      'amount_display',
      'direction'
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
      'customer_profile_id',
      'transaction_type',
      'amount',
      'status',
      'payment_method_last4',
      'notes',
      'stripe_payment_intent_key',
      'stripe_charge_key',
      'processed_at'
    ] if has_role?(user, 'counter_agent')
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
