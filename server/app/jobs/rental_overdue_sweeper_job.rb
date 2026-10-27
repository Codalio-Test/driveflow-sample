# frozen_string_literal: true

# Flips live contracts to `overdue` once the 60-minute grace period has
# expired, and raises a high-priority alert on each newly-overdue rental.
#
# Scheduled from config/recurring.yml. Also runs on demand from the console
# (`RentalOverdueSweeperJob.perform_now`).
class RentalOverdueSweeperJob < ApplicationJob
  queue_as :default

  def perform(now: Time.current)
    newly_overdue = []

    Rental.where(status: %w[confirmed active]).find_each do |rental|
      next if rental.scheduled_return_datetime.blank?
      next if rental.grace_expires_at.blank?
      next if now <= rental.grace_expires_at

      rental.update_columns(status: 'overdue', updated_at: Time.current)
      newly_overdue << rental
      raise_overdue_alert(rental)
    end

    newly_overdue
  end

  private

  def raise_overdue_alert(rental)
    Rails.logger.warn(
      "[DriveFlow][overdue] #{rental.reservation_number} " \
      "(customer #{rental.customer_profile&.full_name}) is " \
      "#{rental.overdue_duration_label} past the #{Rental::LATE_GRACE_MINUTES}-minute grace; " \
      "accrued late fee $#{format('%.2f', rental.late_fee_accrued)}"
    )
  end
end
