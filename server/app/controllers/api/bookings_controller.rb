# frozen_string_literal: true

module Api
  # Public guest booking funnel: create a draft reservation, then confirm it
  # with a card authorization. No account required.
  class BookingsController < PublicController
    def create
      category = public_scope(VehicleCategory).find(params[:vehicle_category_id])
      profile = find_or_build_profile
      return unless profile

      rental = nil
      ActiveRecord::Base.transaction do
        rental = Rental.create!(
          organization_id: current_organization.id,
          customer_profile: profile,
          vehicle_category_id: category.id,
          location_id: params[:location_id],
          vehicle_id: params[:vehicle_id],
          pickup_datetime: params[:pickup_datetime],
          scheduled_return_datetime: params[:scheduled_return_datetime],
          scheduled_duration_days: params[:scheduled_duration_days] || derived_days,
          protection_tier: params[:protection_tier].presence || 'basic',
          dropoff_location_code: params[:dropoff_location_code].presence || params[:location_code],
          status: 'reserved'
        )
        BookingChargeService.new(rental).persist!
      end

      render json: {
        rental: serialize_rental(rental),
        charges: rental.rental_charges.kept.order(:id).map { |c| serialize_charge(c) }
      }, status: :created
    end

    # Commits the reservation: attaches the renter's card, authorizes payment of
    # the itemized total, flips the rental to `confirmed`, and dispatches the
    # voucher email with the QR payload.
    def confirm
      rental = public_scope(Rental).find(params[:rental_id])
      profile = profile_for(rental, params[:full_name], params[:email], params[:phone_number])
      return unless profile

      payment = nil
      ActiveRecord::Base.transaction do
        rental.update!(customer_profile: profile)
        BookingChargeService.new(rental).persist!

        total = rental.rental_charges.kept.sum(:amount).to_d
        # Authorizes through Stripe: a declined card raises PaymentError, which
        # the public controller renders as a 422 with the decline reason so the
        # checkout form keeps the renter's input (AC-16).
        payment = StripePaymentService.new(organization: current_organization).charge_booking(
          rental: rental,
          amount: total.positive? ? total : BigDecimal('0.01'),
          payment_method: params[:stripe_payment_method].presence,
          last4: params[:payment_method_last4].presence
        )

        rental.update!(status: 'confirmed')
        rental.recalculate_totals!
      end

      rental.reload
      NotificationService.new(rental).send_voucher

      render json: {
        rental: serialize_rental(rental),
        payment: { id: payment.id, amount: payment.amount.to_f, status: payment.status },
        qr_code_url: QrCodeService.new(rental).data_uri,
        message: 'Reservation confirmed'
      }, status: :created
    end

    private

    def derived_days
      pickup = Time.zone.parse(params[:pickup_datetime].to_s)
      dropoff = Time.zone.parse(params[:scheduled_return_datetime].to_s)
      [(dropoff - pickup).to_i / 86_400, 1].max
    rescue StandardError
      1
    end

    def renter_params
      (params[:renter] || params).to_unsafe_h
    end

    def find_or_build_profile
      existing = if params[:customer_profile_id].present?
                   public_scope(CustomerProfile).find_by(id: params[:customer_profile_id])
                 elsif renter_params['email'].present?
                   public_scope(CustomerProfile).find_by(email: renter_params['email'])
                 end
      return existing if existing

      CustomerProfile.create!(
        organization_id: current_organization.id,
        full_name: renter_params['full_name'].presence || renter_params['full_name'] || 'Guest renter',
        email: renter_params['email'].presence || renter_params['email'] || 'guest@example.com',
        phone_number: renter_params['phone_number'],
        license_number: renter_params['license_number'],
        license_state: renter_params['license_state'],
        license_expiry_date: renter_params['license_expiry_date'],
        license_country: renter_params['license_country'] || 'USA'
      )
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.to_hash }, status: :unprocessable_entity
      nil
    end

    def profile_for(rental, full_name, email, phone)
      profile = rental.customer_profile || find_or_build_profile
      return nil if profile.nil?

      profile.update!(
        full_name: full_name.presence || profile.full_name,
        email: email.presence || profile.email,
        phone_number: phone.presence || profile.phone_number
      )
      profile
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.to_hash }, status: :unprocessable_entity
      nil
    end

    def serialize_rental(rental)
      serialize_public_rental(rental)
    end

    def serialize_charge(charge)
      serialize_public_charge(charge)
    end
  end
end
