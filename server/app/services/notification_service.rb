# frozen_string_literal: true

# Dispatches the transactional notifications DriveFlow sends to renters:
# booking vouchers, return-urgency notices and settlement receipts.
#
# Delivery is intentionally abstract: email goes through ActionMailer, and the
# SMS leg is recorded on the rental (`last_notified_at` + a Payment-style audit
# note) so the console's timeline reflects what was sent even when no SMS
# provider is configured.
class NotificationService
  CHANNELS = %w[email sms sms+email].freeze

  attr_reader :rental

  def initialize(rental)
    @rental = rental
  end

  def send_voucher
    BookingMailer.voucher(rental).deliver_later
    log_delivery('voucher', 'email')
  end

  def send_urgency_notice(channel: 'sms+email')
    deliver_return_urgency(channel)
  end

  def send_receipt
    BookingMailer.receipt(rental).deliver_later
    log_delivery('receipt', 'email')
  end

  def deliver_return_urgency(channel)
    channel = CHANNELS.include?(channel.to_s) ? channel.to_s : 'sms+email'
    BookingMailer.return_urgency(rental).deliver_later if channel.include?('email')
    log_delivery('return_urgency', channel, sms: channel.include?('sms'))
    rental.update_columns(last_notified_at: Time.current, updated_at: Time.current)
    { channel: channel, late_fee: rental.late_fee_accrued.to_f,
      sent_at: rental.last_notified_at&.iso8601 || Time.current.iso8601 }
  end

  private

  def log_delivery(kind, channel, sms: false)
    rental.update_columns(last_notified_at: Time.current, updated_at: Time.current)
    { kind: kind, channel: channel, sms: sms, sent_at: Time.current.iso8601 }
  end
end
