# frozen_string_literal: true

class Payment < Rhino::RhinoModel
  include Rhino::BelongsToOrganization
  include SoftDeletable

  TRANSACTION_TYPES = %w[
    deposit_hold deposit_capture deposit_release rental_payment
    overdue_settlement refund
  ].freeze
  STATUSES = %w[succeeded pending failed refunded].freeze

  belongs_to :rental
  belongs_to :customer_profile, optional: true

  rhino_filters :rental_id, :customer_profile_id, :transaction_type, :status, :stripe_payment_intent_key
  rhino_sorts :processed_at, :amount, :created_at
  rhino_default_sort '-processed_at'
  rhino_search :notes, :stripe_payment_intent_key
  rhino_fields :id, :rental_id, :customer_profile_id, :stripe_payment_intent_key,
               :stripe_charge_key, :transaction_type, :amount, :status,
               :payment_method_last4, :processed_at, :notes, :created_at
  rhino_includes :rental, :customer_profile
  rhino_pagination_enabled true
  rhino_per_page 25

  validates :transaction_type, presence: true, inclusion: { in: TRANSACTION_TYPES }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :holds, -> { where(transaction_type: 'deposit_hold') }

  def rhino_computed_attributes
    {
      # Prototype `/admin/analytics` + `/account/billing` read `rental`, `type`, `date`.
      'rental' => rental&.reservation_number,
      'type' => transaction_type.humanize,
      'date' => processed_at&.iso8601,
      'last4' => payment_method_last4,
      'reference' => stripe_charge_key.presence || stripe_payment_intent_key,
      'amount_display' => "$#{format('%.2f', amount.to_d)}",
      'direction' => %w[deposit_release refund].include?(transaction_type) ? 'credit' : 'debit'
    }
  end
end
