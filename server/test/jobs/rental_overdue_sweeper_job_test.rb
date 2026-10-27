# frozen_string_literal: true

require "test_helper"

# AC-82 / AC-107 — the overdue sweeper job (60-minute grace is authoritative).
class RentalOverdueSweeperJobTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "sweeper-org")
    @graph = build_rental_graph(organization: @org)
    @rental = @graph[:rental]
  end

  test "beyond the grace period the rental flips to overdue (AC-82)" do
    @rental.update!(status: "active", scheduled_return_datetime: 3.hours.ago)

    newly = RentalOverdueSweeperJob.perform_now

    assert_includes newly.map(&:id), @rental.id
    assert_equal "overdue", @rental.reload.status
  end

  test "inside the grace period nothing changes (AC-82 / AC-127)" do
    @rental.update!(status: "active", scheduled_return_datetime: 30.minutes.ago)

    newly = RentalOverdueSweeperJob.perform_now

    assert_not_includes newly.map(&:id), @rental.id
    assert_equal "active", @rental.reload.status
  end

  test "completed rentals are never swept" do
    @rental.update!(status: "completed", scheduled_return_datetime: 5.hours.ago)
    RentalOverdueSweeperJob.perform_now
    assert_equal "completed", @rental.reload.status
  end

  test "rentals without a scheduled return are skipped" do
    @rental.update!(status: "active", scheduled_return_datetime: nil)
    assert_nothing_raised { RentalOverdueSweeperJob.perform_now }
    assert_equal "active", @rental.reload.status
  end

  test "accrued late fee is bounded by the daily rate on a swept rental (AC-85)" do
    @rental.update!(status: "active", scheduled_return_datetime: 2.days.ago)
    RentalOverdueSweeperJob.perform_now
    @rental.reload
    assert_equal "overdue", @rental.status
    assert_equal @rental.daily_rate_cap, @rental.late_fee_accrued
    assert @rental.late_fee_capped?
    assert @rental.rhino_computed_attributes["overdue_duration"].present?
  end

  test "the sweep is idempotent" do
    @rental.update!(status: "active", scheduled_return_datetime: 3.hours.ago)
    RentalOverdueSweeperJob.perform_now
    second = RentalOverdueSweeperJob.perform_now
    assert_not_includes second.map(&:id), @rental.id
  end
end
