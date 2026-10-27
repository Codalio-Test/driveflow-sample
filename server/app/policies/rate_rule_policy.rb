# frozen_string_literal: true

# Authorization for the `rate_rules` resource.
class RateRulePolicy < Rhino::ResourcePolicy
  self.resource_slug = 'rate_rules'

  def permitted_attributes_for_show(user)
    return ['*'] if has_role?(user, 'fleet_manager')
    return ['*'] if has_role?(user, 'counter_agent')
    return [
      'id',
      'vehicle_category_id',
      'name',
      'season_name',
      'start_date',
      'end_date',
      'daily_multiplier',
      'weekend_multiplier',
      'min_rental_days',
      'is_active',
      'scope',
      'value',
      'priority',
      'rule_type'
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
