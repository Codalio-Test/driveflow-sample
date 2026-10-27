# frozen_string_literal: true

module Api
  # Base class for DriveFlow's custom (non-CRUD) tenant endpoints.
  #
  # These controllers exist for genuinely non-CRUD logic (deposit lifecycle,
  # settlement, fleet matrix, counter queues, analytics, PDFs, uploads). All
  # data access goes through Rhino.query under an explicit
  # for_user/in_organization context, so organization scoping and each model's
  # row-level scope are always applied.
  class BaseController < ActionController::API
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

    rescue_from RentalExtensionService::ExtensionError do |e|
      render json: { errors: { extension: [e.message] }, message: e.message },
             status: :unprocessable_entity
    end

    attr_reader :current_user, :current_organization

    before_action :resolve_organization
    before_action :authenticate_user!

    private

    def resolve_organization
      identifier = params[:organization].presence
      return if identifier.blank?

      column = Rhino.config.multi_tenant[:organization_identifier_column] || 'slug'
      org = Organization.find_by(column => identifier)
      return render(json: { message: 'Organization not found' }, status: :not_found) if org.nil?

      user = bearer_user
      if user && !user.user_roles.exists?(organization_id: org.id)
        return render(json: { message: 'Organization not found' }, status: :not_found)
      end

      @current_organization = org
      request.env['rhino.organization'] = org
      RequestStore.store[:rhino_organization] = org if defined?(RequestStore)
    end

    def authenticate_user!
      user = bearer_user
      return render(json: { message: 'Unauthenticated.' }, status: :unauthorized) if user.nil?

      @current_user = user
      RequestStore.store[:rhino_current_user] = user if defined?(RequestStore)
    end

    def bearer_user
      return @bearer_user if defined?(@bearer_user)

      token = request.headers['Authorization']&.sub(/\ABearer /, '')
      @bearer_user = token.present? ? User.find_by(api_token: token) : nil
    end

    # ------------------------------------------------------------------
    # Authorization helpers
    # ------------------------------------------------------------------

    def permitted?(slug, action)
      current_user.present? && current_user.has_permission?("#{slug}.#{action}", current_organization)
    end

    def authorize_permission!(slug, action)
      return true if permitted?(slug, action)

      render json: { message: 'This action is unauthorized.' }, status: :forbidden
      false
    end

    # The deposit workflow needs Payment store *and* Rental update (cross-resource gate).
    def authorize_deposit!
      return true if permitted?('payments', 'store') && permitted?('rentals', 'update')

      render json: {
        message: "This action is unauthorized. Managing security deposits requires " \
                 "'payments.store' and 'rentals.update' in this organization."
      }, status: :forbidden
      false
    end

    # ------------------------------------------------------------------
    # Tenant-safe data access
    # ------------------------------------------------------------------

    def scoped(model_class)
      Rhino.for_user(current_user).in_organization(current_organization).query(model_class)
    end

    def scoped_scope(model_class, scope_name, *args)
      Rhino.for_user(current_user).in_organization(current_organization)
           .scoped_query(model_class, scope_name, *args)
    end

    def find_rental!(id)
      rental = scoped(Rental).find_by(id: id) || scoped(Rental).find_by(reservation_number: id)
      raise ActiveRecord::RecordNotFound, "Rental #{id}" if rental.nil?

      rental
    end

    def payload
      params.to_unsafe_h.except('controller', 'action', 'format', 'organization')
    end
  end
end
