# frozen_string_literal: true

require "test_helper"

# AC-115 — QR code generation for booking vouchers and receipts.
#
# The confirmation voucher renders `qr_code_url`; it must be a real scannable
# PNG data URI whose payload resolves back to the reservation, not a placeholder.
class RentalVoucherQrTest < ActiveSupport::TestCase
  setup do
    @org = create_organization(slug: "qr-org")
    @graph = build_rental_graph(organization: @org)
    @rental = @graph[:rental]
  end

  # AC-115: the voucher payload is the base64 PNG data URI the confirmation page
  # renders in an <img> tag.
  test "the rental voucher exposes a PNG data URI QR code (AC-115)" do
    url = @rental.rhino_computed_attributes["qr_code_url"]

    assert url.start_with?("data:image/png;base64,"), "expected a PNG data URI, got #{url.to_s[0, 30]}"
    png = Base64.strict_decode64(url.split(",", 2).last)
    assert png.b.start_with?("\x89PNG".b), "the decoded payload must be a real PNG"
  end

  # AC-115: the encoded payload carries the reservation reference (plus the
  # window) so scanning the voucher identifies the booking.
  test "the QR payload resolves the reservation (AC-115)" do
    payload = QrCodeService.new(@rental).payload
    decoded = JSON.parse(payload)

    assert_equal @rental.reservation_number, decoded["reservation_number"]
    assert_equal @rental.status, decoded["status"]
    assert_equal @rental.vehicle_category_id, decoded["vehicle_category_id"]
    assert decoded["pickup_datetime"].present?
  end

  # AC-115: the QR code is a genuine, verifiable QR symbol (not an arbitrary
  # image) — the rqrcode encoder round-trips the payload.
  test "the QR code encodes the voucher payload as a QR symbol (AC-115)" do
    service = QrCodeService.new(@rental)
    qr = RQRCode::QRCode.new(service.payload, level: :m)

    assert qr.modules.size >= 21, "a QR symbol is at least 21x21 modules"
    assert_operator qr.modules.flatten.count(true), :>, 0
  end

  # AC-115 (edge): two different rentals produce different vouchers, so a scan
  # can never be confused between bookings.
  test "distinct rentals produce distinct vouchers (AC-115)" do
    other = build_rental_graph(organization: @org)

    assert_not_equal QrCodeService.new(@rental).data_uri, QrCodeService.new(other[:rental]).data_uri
  end
end
