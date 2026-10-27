# frozen_string_literal: true

require 'prawn'
require 'prawn/table'

# Renders itemized receipts / tax invoices for a completed rental, including
# the Stripe reference numbers so the renter can reconcile the charge.
class ReceiptPdfService
  attr_reader :rental

  def initialize(rental)
    @rental = rental
  end

  def render
    Prawn::Document.new(page_size: 'LETTER', margin: 48) do |pdf|
      pdf.text 'DriveFlow Rental Receipt', size: 20, style: :bold
      pdf.move_down 6
      pdf.text "Reservation #{rental.reservation_number}", size: 12, style: :bold
      pdf.text "Issued #{Time.current.utc.iso8601}", size: 9, color: '666666'
      pdf.move_down 14

      pdf.text 'Renter', style: :bold, size: 12
      pdf.text rental.customer_profile&.full_name.to_s, size: 11
      pdf.text rental.customer_profile&.email.to_s, size: 11
      pdf.move_down 12

      pdf.text 'Itemized Charges', style: :bold, size: 12
      rows = [['Description', 'Qty', 'Unit', 'Amount']]
      rental.rental_charges.kept.order(:id).each do |charge|
        rows << [charge.description, charge.quantity.to_s,
                 "$#{format('%.2f', charge.unit_price.to_d)}",
                 "$#{format('%.2f', charge.amount.to_d)}"]
      end
      pdf.table(rows, header: true, width: pdf.bounds.width, cell_style: { size: 9, padding: 4 }) do
        row(0).font_style = :bold
        columns(1..3).align = :right
      end
      pdf.move_down 8
      pdf.text "Total charges: $#{format('%.2f', rental.total_charges_amount.to_d)}", align: :right
      pdf.text "Total paid: $#{format('%.2f', rental.total_paid_amount.to_d)}", align: :right
      pdf.text "Balance owed: $#{format('%.2f', rental.balance_owed_amount.to_d)}", align: :right, style: :bold
      pdf.move_down 14

      pdf.text 'Payment Transactions', style: :bold, size: 12
      pay_rows = [['Type', 'Reference', 'Amount', 'Status']]
      rental.payments.order(:processed_at).each do |payment|
        pay_rows << [payment.transaction_type.humanize,
                     payment.stripe_charge_key.presence || payment.stripe_payment_intent_key.to_s,
                     "$#{format('%.2f', payment.amount.to_d)}",
                     payment.status]
      end
      pdf.table(pay_rows.presence || [['No transactions', '', '', '']], header: true,
                                                                       width: pdf.bounds.width,
                                                                       cell_style: { size: 9, padding: 4 }) do
        row(0).font_style = :bold
      end
      pdf.move_down 14

      pdf.text 'Tax Invoice Summary', style: :bold, size: 12
      tax = rental.rental_charges.kept.where(charge_type: 'sales_tax').sum(:amount).to_d
      pdf.text "Tax collected: $#{format('%.2f', tax)}", size: 10
      pdf.text "Deposit status: #{rental.deposit_status}", size: 10
    end.render
  end
end
