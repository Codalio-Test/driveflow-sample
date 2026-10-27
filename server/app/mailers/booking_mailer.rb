# frozen_string_literal: true

# Transactional renter notifications: booking voucher, return-urgency notice
# and settlement receipt.
class BookingMailer < ApplicationMailer
  def voucher(rental)
    @rental = rental
    mail(
      to: renter_email(rental),
      subject: "Your DriveFlow booking #{rental.reservation_number} is confirmed"
    ) do |format|
      format.text { render plain: voucher_body(rental) }
    end
  end

  def return_urgency(rental)
    @rental = rental
    mail(
      to: renter_email(rental),
      subject: "Action required: #{rental.reservation_number} is past its return time"
    ) do |format|
      format.text { render plain: urgency_body(rental) }
    end
  end

  def receipt(rental)
    @rental = rental
    mail(
      to: renter_email(rental),
      subject: "Your DriveFlow receipt for #{rental.reservation_number}"
    ) do |format|
      format.text { render plain: receipt_body(rental) }
    end
  end

  private

  def renter_email(rental)
    rental.customer_profile&.email.presence || 'guest@example.com'
  end

  def voucher_body(rental)
    <<~TEXT
      Reservation: #{rental.reservation_number}
      Status: #{rental.status}
      Pickup: #{rental.pickup_datetime}
      Scheduled return: #{rental.scheduled_return_datetime}
      Class: #{rental.vehicle_category&.name}
      Total: $#{format('%.2f', rental.total_charges_amount.to_d)}
      Deposit status: #{rental.deposit_status}
    TEXT
  end

  def urgency_body(rental)
    <<~TEXT
      Your rental #{rental.reservation_number} is past its scheduled return time.

      Scheduled return: #{rental.scheduled_return_datetime}
      Grace period expired: #{rental.grace_expires_at}
      Billable overdue hours: #{rental.billable_overdue_hours}
      Accrued late fee: $#{format('%.2f', rental.late_fee_accrued)}

      Please return the vehicle or contact the branch to extend the contract.
    TEXT
  end

  def receipt_body(rental)
    lines = rental.rental_charges.kept.order(:id).map do |charge|
      "#{charge.description}: $#{format('%.2f', charge.amount.to_d)}"
    end
    <<~TEXT
      Reservation: #{rental.reservation_number}

      #{lines.join("\n")}

      Total charges: $#{format('%.2f', rental.total_charges_amount.to_d)}
      Total paid: $#{format('%.2f', rental.total_paid_amount.to_d)}
      Balance owed: $#{format('%.2f', rental.balance_owed_amount.to_d)}
    TEXT
  end
end
