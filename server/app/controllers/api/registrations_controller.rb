# frozen_string_literal: true

module Api
  # Open customer self-registration (Rhino v4's built-in registration is
  # invitation-token based, so the public /signup flow is custom work).
  #
  # Creates an account with `approved = false` and emails a verification link;
  # the account is approved when the token is redeemed.
  class RegistrationsController < PublicController
    # POST /api/auth/register — the single public registration entry point the
    # SPA uses.
    #
    # Two flows share the route:
    #   * with an invitation `token` → the Rhino staff onboarding flow (create
    #     the account, accept the invitation, return a bearer token).
    #   * without a token → open customer self-registration (approved = false
    #     until the emailed verification link is redeemed).
    def register
      return invitation_register if params[:token].present?

      create
    end

    def create
      user = User.new(
        name: params[:name],
        first_name: params[:first_name],
        last_name: params[:last_name],
        email: params[:email].to_s.strip.downcase,
        phone_number: params[:phone_number],
        password: params[:password],
        password_confirmation: params[:password_confirmation].presence || params[:password],
        approved: false
      )

      return render_validation(user) unless user.save

      customer_role = Role.find_by(slug: 'customer') || Role.first
      UserRole.find_or_create_by!(user: user, organization: current_organization, role: customer_role) if customer_role

      CustomerProfile.create!(
        organization_id: current_organization.id,
        user_id: user.id,
        full_name: user.display_name,
        email: user.email,
        phone_number: user.phone_number
      )

      token = user.issue_verification_token!
      VerificationMailer.verify_email(user).deliver_later

      render json: {
        message: 'Account created. Check your email to verify your address.',
        user: user_json(user),
        verification_token: token,
        organization_slug: current_organization.slug
      }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.to_hash }, status: :unprocessable_entity
    end

    def verify
      token = params[:token].presence || params[:verification_token].presence
      user = User.find_by(verification_token: token) if token

      return render(json: { message: 'Invalid or expired verification token' }, status: :unprocessable_entity) if user.nil?

      user.verify_email!
      render json: { message: 'Email verified', user: user_json(user) }, status: :ok
    end

    private

    # Staff onboarding: redeems an invitation token issued through the Rhino
    # invitations endpoints. Mirrors Rhino::AuthController#register_with_invitation.
    def invitation_register
      invitation = Rhino::OrganizationInvitation.find_by(token: params[:token], status: 'pending')

      if invitation.nil?
        return render json: { message: 'Invalid or expired invitation token' }, status: :not_found
      end

      if invitation.expired?
        invitation.update!(status: 'expired')
        return render json: { message: 'This invitation has expired' }, status: :unprocessable_entity
      end

      if invitation.email != params[:email].to_s.strip.downcase
        return render json: { message: 'Email does not match the invitation' }, status: :unprocessable_entity
      end

      user = User.new(
        name: params[:name],
        email: params[:email].to_s.strip.downcase,
        password: params[:password],
        password_confirmation: params[:password_confirmation].presence || params[:password],
        approved: true
      )
      return render_validation(user) unless user.save

      invitation.accept!(user)
      # `regenerate_api_token` persists and returns true, so read the attribute.
      user.regenerate_api_token
      token = user.api_token

      render json: {
        message: 'Registration successful',
        token: token,
        user: user_json(user),
        organization_slug: invitation.organization&.slug
      }, status: :created
    end

    def render_validation(user)
      render json: { errors: user.errors.to_hash }, status: :unprocessable_entity
    end

    def user_json(user)
      {
        id: user.id, name: user.display_name, email: user.email,
        approved: user.approved, email_verified_at: user.email_verified_at&.iso8601
      }
    end
  end
end
