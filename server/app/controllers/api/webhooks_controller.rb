# frozen_string_literal: true

module Api
  # Stripe webhook reconciliation. Deliberately outside the authenticated API:
  # Stripe is the caller. When `STRIPE_WEBHOOK_SECRET` is configured the
  # signature is verified before the event is reconciled.
  class WebhooksController < ActionController::API
    def stripe
      payload = request.raw_post
      event = JSON.parse(payload)
      return render(json: { message: 'Invalid event' }, status: :bad_request) unless event.is_a?(Hash)

      if webhook_secret.present?
        verification = verify_signature(payload)
        return render(json: { message: verification }, status: :bad_request) if verification.is_a?(String)
      end

      payment = StripePaymentService.new.reconcile_event(event)

      render json: {
        received: true,
        type: event['type'],
        reconciled_payment_id: payment&.id
      }, status: :ok
    rescue JSON::ParserError
      render json: { message: 'Invalid payload' }, status: :bad_request
    end

    private

    def webhook_secret
      ENV['STRIPE_WEBHOOK_SECRET'].presence
    end

    def verify_signature(payload)
      signature = request.headers['Stripe-Signature']
      return 'Missing Stripe-Signature header' if signature.blank?

      Stripe::Webhook.construct_event(payload, signature, webhook_secret)
      true
    rescue Stripe::SignatureVerificationError => e
      e.message
    end
  end
end
