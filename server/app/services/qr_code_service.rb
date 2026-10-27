# frozen_string_literal: true

require 'rqrcode'
require 'base64'

# Renders a scannable QR code for a rental voucher / receipt as a PNG data URI
# (the shape the prototype's confirmation page consumes: `qr_code_url`).
class QrCodeService
  attr_reader :rental

  def initialize(rental)
    @rental = rental
  end

  def payload
    {
      reservation_number: rental.reservation_number,
      status: rental.status,
      pickup_datetime: rental.pickup_datetime&.iso8601,
      scheduled_return_datetime: rental.scheduled_return_datetime&.iso8601,
      vehicle_category_id: rental.vehicle_category_id
    }.to_json
  end

  def png
    RQRCode::QRCode.new(payload, level: :m).as_png(size: 240, border_modules: 2).to_s
  end

  def data_uri
    "data:image/png;base64,#{Base64.strict_encode64(png)}"
  end
end
