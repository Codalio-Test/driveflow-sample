# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check
  get 'up' => 'rails/health#show', as: :rails_health_check

  # ---------------------------------------------------------------------------
  # DriveFlow custom API
  #
  # Rhino draws the generated CRUD routes for every registered model (appended
  # after this file), so only genuinely non-CRUD endpoints are declared here.
  # Public endpoints are registered both flat (/api/...) and organization-scoped
  # (/api/:organization/...) because the SPA's raw `api.post('/bookings/confirm')`
  # call does not carry the organization segment.
  # ---------------------------------------------------------------------------
  scope path: 'api', defaults: { format: :json } do
    # Stripe is the caller — never authenticated by our Bearer token.
    post 'webhooks/stripe', to: 'api/webhooks#stripe'

    public_endpoints = lambda do
      get  'vehicle_catalog', to: 'api/vehicle_catalog#index'
      get  'availability', to: 'api/availability#index'
      post 'bookings', to: 'api/bookings#create'
      post 'bookings/confirm', to: 'api/bookings#confirm'
      post 'registrations', to: 'api/registrations#create'
      post 'registrations/verify', to: 'api/registrations#verify'
      # The SPA registers at /api/auth/register. This override takes precedence
      # over the engine's invitation-only route and handles BOTH flows: with a
      # `token` it redeems a staff invitation, without one it is open customer
      # self-registration.
      post 'auth/register', to: 'api/registrations#register'
    end

    instance_exec(&public_endpoints)

    scope ':organization' do
      instance_exec(&public_endpoints)
    end

    # -------------------------------------------------------------------------
    # Authenticated (tenant-scoped) custom endpoints
    # -------------------------------------------------------------------------
    scope ':organization' do
      # The signed-in user's identity + roles for this organization. Any
      # authenticated member may read their own record; no slug permission is
      # required because it exposes nothing but the caller's own membership.
      get 'me', to: 'api/me#show'

      # Security deposit lifecycle + balance recovery
      post 'payments/hold', to: 'api/payments#hold'
      post 'payments/expand_hold', to: 'api/payments#expand_hold'
      post 'payments/capture', to: 'api/payments#capture'
      post 'payments/release', to: 'api/payments#release'
      post 'payments/settle', to: 'api/payments#settle'
      post 'payments/charge_balance', to: 'api/payments#charge_balance'
      post 'payments/refund', to: 'api/payments#refund'
      post 'payments/methods', to: 'api/payments#methods'

      # Bulk fleet operations
      post 'vehicles/bulk', to: 'api/vehicles#bulk'

      # Digital agreement + handover
      get  'agreements', to: 'api/agreements#show'
      post 'agreements/sign', to: 'api/agreements#sign'
      post 'agreements/complete_handover', to: 'api/agreements#complete_handover'

      # Rental operations
      get  'rentals/export', to: 'api/rentals#csv', defaults: { format: 'csv' }
      get  'rentals/:id/agreement', to: 'api/agreements#show'
      get  'rentals/:id/settlement_preview', to: 'api/rentals#settlement_preview'
      get  'rentals/:id/inspection_comparison', to: 'api/rentals#inspection_comparison'
      get  'rentals/:id/receipt', to: 'api/rentals#receipt'
      post 'rentals/:id/notify', to: 'api/rentals#notify'
      post 'rentals/:id/notes', to: 'api/rentals#notes'
      post 'rentals/:id/escalate', to: 'api/rentals#escalate'
      post 'rentals/:id/extend', to: 'api/rentals#extend'
      post 'rentals/:id/finalize', to: 'api/rentals#finalize'

      # Tablet inspections
      get  'inspections/:id/comparison', to: 'api/inspections#comparison'
      post 'inspections/:id/photos', to: 'api/inspections#photos'
      post 'inspections/:id/finish', to: 'api/inspections#finish'

      # Counter queues
      get 'counter/departures', to: 'api/counter#departures'
      get 'counter/returns', to: 'api/counter#returns'
      get 'counter/lookup', to: 'api/counter#lookup'

      # Fleet schedule matrix
      get 'fleet_matrix', to: 'api/fleet#matrix'

      # Analytics
      get 'analytics', to: 'api/analytics#show'
      get 'analytics/export', to: 'api/analytics#export', defaults: { format: 'csv' }

      # Accounts receivable
      get 'billing/outstanding', to: 'api/billing#outstanding'

      # Receipts / invoices
      get 'receipts', to: 'api/receipts#index'
      get 'receipts/:rental_id', to: 'api/receipts#show'
      get 'receipts/:rental_id/invoice', to: 'api/receipts#invoice'

      # Uploads
      post 'documents', to: 'api/documents#create'
      post 'documents/attach_to_damage', to: 'api/documents#attach_to_damage'
    end
  end
end
