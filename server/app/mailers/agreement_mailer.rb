# frozen_string_literal: true

# Emails the executed rental agreement PDF to the renter.
class AgreementMailer < ApplicationMailer
  def executed_agreement(rental, pdf:)
    @rental = rental
    attachments["driveflow-agreement-#{rental.reservation_number}.pdf"] = pdf

    mail(
      to: rental.customer_profile&.email.presence || 'guest@example.com',
      subject: "Your executed DriveFlow rental agreement (#{rental.reservation_number})"
    ) do |format|
      format.text { render plain: body_for(rental) }
    end
  end

  private

  def body_for(rental)
    <<~TEXT
      Your rental agreement for reservation #{rental.reservation_number} has been executed.

      Signed by: #{rental.agreement_signed_by_name}
      Signed at: #{rental.agreement_signed_at&.utc&.iso8601} (UTC)

      The signed agreement is attached to this email.
    TEXT
  end
end
