# frozen_string_literal: true

require "test_helper"

# AC-108 — the SMS/email notification service behind the voucher, the return
# urgency notice and the settlement receipt.
#
# Runs against ActionMailer directly (no ActionMailer::TestCase dependency); the
# test environment's :test delivery method is irrelevant because the messages
# are rendered but never delivered.
class BookingMailerTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "mailer-org")
    @graph = build_rental_graph(organization: @org)
    @rental = @graph[:rental]
    @renter_email = @graph[:profile].email
  end

  # AC-108: the booking voucher is emailed to the renter with the reservation
  # reference (AC-17's "automated email voucher").
  test "the booking voucher is addressed to the renter and names the reference (AC-108)" do
    mail = BookingMailer.voucher(@rental)

    assert_equal [@renter_email], mail.to
    assert_match @rental.reservation_number, mail.subject
    assert_match @rental.reservation_number, mail.body.encoded
    assert_match(/Deposit status/, mail.body.encoded)
  end

  # AC-108: the return urgency notice lists the grace expiry and the accrued
  # late fee so the renter can act.
  test "the return urgency notice itemizes the late penalty (AC-108)" do
    @rental.update!(scheduled_return_datetime: 3.hours.ago, status: "overdue")

    mail = BookingMailer.return_urgency(@rental)

    assert_equal [@renter_email], mail.to
    assert_match(/past its return time/, mail.subject)
    body = mail.body.encoded
    assert_match(/Grace period expired/, body)
    assert_match(/Accrued late fee/, body)
    assert_match(/Billable overdue hours/, body)
  end

  # AC-108: the settlement receipt itemizes each charge line.
  test "the receipt email itemizes the settlement charges (AC-108)" do
    RentalCharge.create!(organization: @org, rental: @rental, charge_type: "refueling_charge",
                         description: "Refueling surcharge", unit_price: 8, quantity: 2, amount: 16)

    mail = BookingMailer.receipt(@rental)

    assert_equal [@renter_email], mail.to
    assert_match @rental.reservation_number, mail.subject
    assert_match(/Refueling surcharge/, mail.body.encoded)
    assert_match(/Balance owed/, mail.body.encoded)
  end

  # AC-108: NotificationService is the single entry point the controllers call;
  # it dispatches the message AND timestamps the delivery on the rental.
  test "the notification service dispatches the voucher and stamps the delivery (AC-108)" do
    result = NotificationService.new(@rental).send_voucher

    assert_equal "voucher", result[:kind]
    assert_equal "email", result[:channel]
    assert_not_nil @rental.reload.last_notified_at
  end

  # AC-108 / AC-86: an urgency notice records the channel it used (SMS, email or
  # both) and reports the current late fee.
  test "the urgency notice records the channel and the late fee (AC-108)" do
    @rental.update!(scheduled_return_datetime: 2.hours.ago)
    result = NotificationService.new(@rental).send_urgency_notice(channel: "sms")

    assert_equal "sms", result[:channel]
    assert_equal @rental.late_fee_accrued.to_f, result[:late_fee]
    assert_not_nil @rental.reload.last_notified_at
  end
end
