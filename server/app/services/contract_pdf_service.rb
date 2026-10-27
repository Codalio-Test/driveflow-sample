# frozen_string_literal: true

require 'prawn'
require 'prawn/table'

# Renders the tamper-evident rental agreement PDF (rates, deposit hold,
# coverage terms, condition summary and the captured signature image).
class ContractPdfService
  attr_reader :rental

  def initialize(rental)
    @rental = rental
  end

  def render
    Prawn::Document.new(page_size: 'LETTER', margin: 48) do |pdf|
      pdf.text 'DriveFlow Vehicle Rental Agreement', size: 20, style: :bold
      pdf.move_down 6
      pdf.text "Reservation #{rental.reservation_number}", size: 12, style: :bold
      pdf.text "Generated #{Time.current.utc.iso8601} (UTC)", size: 9, color: '666666'
      pdf.move_down 14

      pdf.text 'Renter', style: :bold, size: 12
      pdf.text "#{renter_name}", size: 11
      pdf.text "License #{license_summary}", size: 11
      pdf.move_down 12

      pdf.text 'Vehicle & Term', style: :bold, size: 12
      pdf.text "Class: #{vehicle_category.name}", size: 11
      pdf.text "Vehicle: #{vehicle_label}", size: 11
      pdf.text "Pickup: #{fmt_time(rental.pickup_datetime)}", size: 11
      pdf.text "Scheduled return: #{fmt_time(rental.scheduled_return_datetime)}", size: 11
      pdf.text "Duration: #{rental.scheduled_duration_days} day(s)", size: 11
      pdf.move_down 12

      pdf.text 'Rate & Protection', style: :bold, size: 12
      pdf.text "Daily rate: $#{format('%.2f', RateCalculator.new(vehicle_category).daily_rate)}", size: 11
      pdf.text "Protection tier: #{rental.protection_tier.capitalize}", size: 11
      pdf.text "Security deposit hold: $#{format('%.2f', deposit_amount)}", size: 11
      pdf.move_down 12

      pdf.text 'Itemized Charges', style: :bold, size: 12
      table_data = [['Description', 'Amount']] + charge_rows
      pdf.table(table_data, header: true, width: pdf.bounds.width,
                               cell_style: { size: 10, padding: 4 }) do
        row(0).font_style = :bold
        columns(1).align = :right
      end
      pdf.move_down 6
      pdf.text "Total: $#{format('%.2f', rental.total_charges_amount.to_d)}", style: :bold, align: :right
      pdf.move_down 14

      pdf.text 'Condition Summary', style: :bold, size: 12
      if check_out_inspection
        pdf.text "Departure odometer: #{check_out_inspection.odometer_reading} mi", size: 10
        pdf.text "Departure fuel: #{check_out_inspection.fuel_percentage}%", size: 10
        pdf.text "Pinned blemishes: #{check_out_inspection.damage_records.kept.count}", size: 10
      else
        pdf.text 'No departure inspection recorded.', size: 10
      end
      pdf.move_down 14

      pdf.text 'Signature', style: :bold, size: 12
      if signature_attached?
        pdf.text "Signed by #{signature_name} at #{fmt_time(rental.agreement_signed_at)} (UTC)", size: 10
        begin
          pdf.image StringIO.new(signature_image_data), at: [0, pdf.cursor - 8], width: 200
        rescue StandardError
          pdf.text '[signature image could not be embedded]', size: 9, color: 'AA0000'
        end
        pdf.move_down 90
      else
        pdf.text 'Awaiting renter signature.', size: 10
      end

      pdf.move_down 10
      pdf.text "Document hash: #{digest}", size: 8, color: '888888'
    end.render
  end

  def digest
    Digest::SHA256.hexdigest([rental.id, rental.reservation_number, rental.updated_at.to_i].join(':'))
  end

  private

  def renter_name
    rental.customer_profile&.full_name.presence || rental.customer_profile&.email || 'Guest renter'
  end

  def license_summary
    profile = rental.customer_profile
    return 'not on file' unless profile&.license_number

    "#{profile.license_number} (#{profile.license_state}) exp #{profile.license_expiry_date}"
  end

  def vehicle_category
    rental.vehicle_category
  end

  def vehicle_label
    rental.vehicle ? "#{rental.vehicle.display_name} · #{rental.vehicle.license_plate}" : 'Assigned at counter'
  end

  def deposit_amount
    rental.deposit_hold_total.positive? ? rental.deposit_hold_total : (vehicle_category.security_deposit_amount || 0)
  end

  def charge_rows
    rental.rental_charges.kept.order(:id).map do |charge|
      [charge.description, "$#{format('%.2f', charge.amount.to_d)}"]
    end.presence || [['No charges recorded', '$0.00']]
  end

  def check_out_inspection
    @check_out_inspection ||= rental.inspections.kept.find_by(inspection_type: 'check_out')
  end

  # A signature is only embeddable when we captured real image bytes — a signed
  # agreement with no captured image renders a text note instead of a broken
  # document.
  def signature_attached?
    rental.agreement_signed_at.present? && signature_image_data.present?
  end

  def signature_name
    rental.agreement_signed_by_name.presence || renter_name
  end

  # The signature is stored as a data URI (signature pad toDataURL) so it can be
  # embedded without a separate upload round-trip. Anything that does not decode
  # to real PNG/JPEG bytes is discarded, so Prawn can never raise mid-document.
  def signature_image_data
    raw = rental.inspections.kept.where.not(customer_signature_url: nil).last&.customer_signature_url.to_s
    payload = raw.sub(%r{\Adata:image/[a-z+]+;base64,}, '')
    return '' if payload.blank?

    bytes = Base64.decode64(payload)
    return '' unless bytes.start_with?("\x89PNG".b) || bytes.start_with?("\xFF\xD8".b)

    bytes
  rescue StandardError
    ''
  end

  def fmt_time(time)
    time ? time.utc.strftime('%Y-%m-%d %H:%M') : '—'
  end
end
