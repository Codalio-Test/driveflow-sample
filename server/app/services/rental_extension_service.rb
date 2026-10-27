# frozen_string_literal: true

# Approves a customer-requested rental extension: validates the fleet buffer,
# moves the return window, reprices the reservation and clears overdue state.
class RentalExtensionService
  class ExtensionError < StandardError; end

  attr_reader :rental, :new_return_datetime

  def initialize(rental, new_return_datetime:)
    @rental = rental
    @new_return_datetime = new_return_datetime
  end

  def call
    raise ExtensionError, 'A new return time is required' if new_return_datetime.blank?
    raise ExtensionError, 'The new return time must be after the current one' if new_return_datetime <= rental.scheduled_return_datetime
    unless buffer_available?
      raise ExtensionError, 'The vehicle is committed to another reservation in that window'
    end

    ActiveRecord::Base.transaction do
      extra_days = ((new_return_datetime - rental.scheduled_return_datetime) / 1.day).ceil
      rental.update!(
        scheduled_return_datetime: new_return_datetime,
        scheduled_duration_days: rental.scheduled_duration_days.to_i + [extra_days, 0].max,
        extension_count: rental.extension_count.to_i + 1,
        status: rental.status == 'overdue' ? 'active' : rental.status
      )

      BookingChargeService.new(rental).persist!
      rental.recalculate_totals!
    end

    rental.reload
  end

  private

  # A vehicle is free if no other live contract on the same vehicle overlaps the
  # extended window.
  def buffer_available?
    return true if rental.vehicle_id.blank?

    conflicts = Rental.where(vehicle_id: rental.vehicle_id, status: %w[reserved confirmed active overdue])
                      .where.not(id: rental.id)
                      .where('pickup_datetime < ? AND scheduled_return_datetime > ?',
                             new_return_datetime, rental.scheduled_return_datetime)
    !conflicts.exists?
  end
end
