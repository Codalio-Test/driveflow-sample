# frozen_string_literal: true

# Email-verification link for the custom open customer registration flow
# (Rhino v4's own registration is invitation-token based).
class VerificationMailer < ApplicationMailer
  def verify_email(user)
    @user = user
    @token = user.verification_token

    mail(to: user.email, subject: 'Verify your DriveFlow account') do |format|
      format.text { render plain: body_for(user) }
    end
  end

  private

  def body_for(user)
    <<~TEXT
      Welcome to DriveFlow, #{user.display_name}!

      Confirm your email address to activate your account:

      #{verification_url(user.verification_token)}

      If you did not create this account you can ignore this message.
    TEXT
  end

  def verification_url(token)
    base = ENV.fetch('DRIVEFLOW_CLIENT_URL', 'http://localhost:5173')
    "#{base}/login?verification_token=#{token}"
  end
end
