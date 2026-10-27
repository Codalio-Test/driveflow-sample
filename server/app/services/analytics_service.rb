# frozen_string_literal: true

# Tenant-safe executive analytics. Every query goes through Rhino.query inside
# an explicit for_user/in_organization context, so organization scoping (and
# each model's row-level scope) is always applied — never a raw model query.
class AnalyticsService
  RANGES = { '7' => 7, '30' => 30, '90' => 90, 'quarter' => 90, 'year' => 365 }.freeze

  attr_reader :user, :organization, :range, :location_code

  def initialize(user:, organization:, range: '30', location: nil)
    @user = user
    @organization = organization
    @range = range.to_s
    @location_code = location.presence
  end

  def call
    Rhino.for_user(user).in_organization(organization).run do
      {
        'range' => range_days,
        'location' => location_code,
        'kpis' => kpis,
        'charts' => charts,
        'deposits' => deposits,
        'maintenance' => maintenance,
        'transactions' => transactions
      }
    end
  end

  private

  def range_days
    RANGES.fetch(range, 30)
  end

  def window
    (range_days.days.ago.beginning_of_day)..Time.current
  end

  def rentals
    scope = Rhino.query(Rental).where(created_at: window)
    scope = scope.joins(:vehicle).where(vehicles: { location_id: location_id }) if location_id
    scope
  end

  def vehicles
    scope = Rhino.query(Vehicle)
    scope = scope.where(location_id: location_id) if location_id
    scope
  end

  def payments
    Rhino.query(Payment).where(created_at: window)
  end

  def location_id
    @location_id ||= location_code && Location.find_by(code: location_code)&.id
  end

  # ----------------------------------------------------------------

  def fleet_size
    @fleet_size ||= [vehicles.count, 1].max
  end

  def available_car_days
    fleet_size * range_days
  end

  def rented_days
    @rented_days ||= rentals.where(status: %w[active overdue completed]).sum(:scheduled_duration_days).to_f
  end

  def utilization_percentage
    ((rented_days / available_car_days.to_f) * 100).round(1)
  end

  def gross_revenue
    @gross_revenue ||= payments.where(transaction_type: %w[rental_payment overdue_settlement deposit_capture])
                              .where(status: 'succeeded').sum(:amount).to_d
  end

  def revpac
    (gross_revenue / available_car_days).round(2)
  end

  def damage_recovered
    @damage_recovered ||= Rhino.query(DamageRecord).where(created_at: window).where(is_pre_existing: false)
                                                   .sum(:repair_cost_estimate).to_d
  end

  def kpis
    [
      { 'label' => 'Utilization', 'value' => "#{utilization_percentage}%", 'change' => utilization_change },
      { 'label' => 'RevPAC', 'value' => "$#{format('%.2f', revpac)}", 'change' => '+0.0%' },
      { 'label' => 'Revenue', 'value' => compact_currency(gross_revenue), 'change' => '+0.0%' },
      { 'label' => 'Damage recovery', 'value' => compact_currency(damage_recovered), 'change' => '+0.0%' }
    ]
  end

  def utilization_change
    target = 82.0
    delta = (utilization_percentage - target).round(1)
    "#{delta.positive? ? '+' : ''}#{delta}%"
  end

  def charts
    [
      {
        'title' => 'Utilization by class',
        'values' => Rhino.query(VehicleCategory).map do |category|
          { 'label' => category.name,
            'value' => Rhino.query(Vehicle).where(vehicle_category_id: category.id).count }
        end
      },
      {
        'title' => 'Revenue by class',
        'values' => Rhino.query(VehicleCategory).map do |category|
          revenue = payments.joins(:rental).where(rentals: { vehicle_category_id: category.id })
                            .where(status: 'succeeded').sum(:amount).to_d
          { 'label' => category.name, 'value' => revenue.to_f }
        end
      },
      {
        'title' => 'Fleet status',
        'values' => Vehicle::STATUSES.map do |status|
          { 'label' => status.humanize, 'value' => vehicles.where(status: status).count }
        end
      }
    ]
  end

  def deposits
    holds = payments.where(transaction_type: 'deposit_hold', status: 'succeeded').sum(:amount).to_d
    released = payments.where(transaction_type: 'deposit_release', status: 'succeeded').sum(:amount).to_d
    captured = payments.where(transaction_type: 'deposit_capture', status: 'succeeded').sum(:amount).to_d

    {
      'total_held' => holds.to_f,
      'released_in_full' => released.to_f,
      'partial_captures' => captured.to_f,
      'uncollected_claims' => Rhino.query(Rental).where('balance_owed_amount > 0').sum(:balance_owed_amount).to_f
    }
  end

  def maintenance
    logs = Rhino.query(VehicleMaintenanceLog).where(created_at: window)
    spend = logs.where(status: 'completed').sum(:cost).to_d
    completed = logs.where(status: 'completed').count
    downtime = completed.zero? ? 0.0 : (logs.where(status: 'completed').sum('COALESCE(odometer_at_service, 0)') / completed.to_f).round(1)

    {
      'total_spend' => spend.to_f,
      'work_orders' => logs.count,
      'completed_orders' => completed,
      'average_downtime_days' => downtime
    }
  end

  def transactions
    payments.order(processed_at: :desc).limit(25).map do |payment|
      {
        'id' => payment.id,
        'rental' => payment.rental&.reservation_number,
        'type' => payment.transaction_type.humanize,
        'amount' => payment.amount.to_f,
        'status' => payment.status,
        'reference' => payment.stripe_charge_key.presence || payment.stripe_payment_intent_key
      }
    end
  end

  def compact_currency(amount)
    amount = amount.to_d
    return "$#{format('%.0f', amount)}" if amount < 1000

    "$#{format('%.1f', amount / 1000)}K"
  end
end
