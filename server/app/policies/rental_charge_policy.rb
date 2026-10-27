# frozen_string_literal: true

# Authorization for the `rental_charges` resource.
class RentalChargePolicy < Rhino::ResourcePolicy
  self.resource_slug = 'rental_charges'

  def permitted_attributes_for_show(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return ['*'] if has_role?(user, 'counter_agent')
    return [
      'id',
      'rental_id',
      'charge_type',
      'description',
      'unit_price',
      'quantity',
      'amount',
      'total',
      'label',
      'category'
    ] if has_role?(user, 'customer')
    []
  end

  def hidden_attributes_for_show(_user)
    []
  end

  def permitted_attributes_for_create(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return ['*'] if has_role?(user, 'counter_agent')
    return [] if has_role?(user, 'customer')
    []
  end

  def permitted_attributes_for_update(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return [
      'description',
      'unit_price',
      'quantity',
      'amount'
    ] if has_role?(user, 'counter_agent')
    return [] if has_role?(user, 'customer')
    []
  end
end
