# frozen_string_literal: true

# Authorization for the `customer_profiles` resource.
class CustomerProfilePolicy < Rhino::ResourcePolicy
  self.resource_slug = 'customer_profiles'

  def permitted_attributes_for_show(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return ['*'] if has_role?(user, 'counter_agent')
    return [
      'id',
      'full_name',
      'email',
      'phone_number',
      'date_of_birth',
      'address',
      'license_state',
      'license_expiry_date',
      'license_country',
      'license_verified',
      'rental_count',
      'guest',
      'license_expired',
      'license_valid',
      'card_last4',
      'card_brand'
    ] if has_role?(user, 'customer')
    []
  end

  def hidden_attributes_for_show(_user)
    []
  end

  def permitted_attributes_for_create(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return [
      'full_name',
      'email',
      'license_number',
      'license_state',
      'license_expiry_date',
      'license_country',
      'phone_number',
      'date_of_birth',
      'address'
    ] if has_role?(user, 'counter_agent')
    return [] if has_role?(user, 'customer')
    []
  end

  def permitted_attributes_for_update(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return [
      'full_name',
      'email',
      'license_number',
      'license_state',
      'license_expiry_date',
      'license_country',
      'license_verified',
      'phone_number',
      'date_of_birth',
      'address'
    ] if has_role?(user, 'counter_agent')
    return [
      'full_name',
      'email',
      'phone_number',
      'date_of_birth',
      'address',
      'license_number',
      'license_state',
      'license_expiry_date',
      'license_country'
    ] if has_role?(user, 'customer')
    []
  end
end
