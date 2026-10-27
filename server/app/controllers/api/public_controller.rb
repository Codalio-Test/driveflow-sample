# frozen_string_literal: true

module Api
  # Base class for the public (anonymous) booking surface. No authentication is
  # required; the organization is resolved from the route segment, an explicit
  # `organization` / `organization_slug` param, or the first organization.
  class PublicController < ActionController::API
    wrap_parameters false

    rescue_from ActiveRecord::RecordNotFound do
      render json: { message: 'Resource not found' }, status: :not_found
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      render json: { errors: e.record.errors.to_hash }, status: :unprocessable_entity
    end

    rescue_from ActionController::ParameterMissing do |e|
      render json: { errors: { e.param => ['is required'] } }, status: :unprocessable_entity
    end

    rescue_from StripePaymentService::PaymentError do |e|
      render json: { errors: { payment: [e.message] }, message: e.message, code: e.code },
             status: :unprocessable_entity
    end

    attr_reader :current_organization

    before_action :resolve_public_organization

    private

    def resolve_public_organization
      identifier = params[:organization].presence ||
                   params[:organization_slug].presence ||
                   public_payload['organization_slug'].presence
      column = Rhino.config.multi_tenant[:organization_identifier_column] || 'slug'

      org = if identifier.present?
              Organization.find_by(column => identifier)
            else
              Organization.order(:id).first
            end

      return render(json: { message: 'Organization not found' }, status: :not_found) if org.nil?

      @current_organization = org
      request.env['rhino.organization'] = org
      RequestStore.store[:rhino_organization] = org if defined?(RequestStore)
    end

    def public_payload
      @public_payload ||= params.to_unsafe_h.except('controller', 'action', 'format')
    end

    # Public endpoints query through the organization context only — there is no
    # user, so Rhino.query is driven with an explicit nil user.
    def public_scope(model_class)
      Rhino.for_user(nil).in_organization(current_organization).query(model_class)
    end

    # `as_rhino_json` is deliberately fail-closed for a nil user (a policy with
    # no matching role branch hides every column), so public endpoints build
    # their own payload from the columns the funnel needs. The guest's own
    # rental/voucher data is not tenant-secret; no other organization's rows are
    # reachable because the relation is org scoped.
    def public_json(record, extra = {})
      record.as_json(except: %w[discarded_at created_at updated_at]).merge(extra)
    end

    def serialize_public_rental(rental)
      return nil if rental.nil?

      public_json(rental, rental.rhino_computed_attributes)
    end

    def serialize_public_charge(charge)
      public_json(charge, charge.rhino_computed_attributes)
    end
  end
end
