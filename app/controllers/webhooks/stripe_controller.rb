module Webhooks
  class StripeController < BaseController
    # POST /webhooks/stripe
    def create
      sig_header = request.headers["Stripe-Signature"]
      endpoint_secret = ENV.fetch("STRIPE_WEBHOOK_SECRET")

      begin
        event = Stripe::Webhook.construct_event(@raw_body, sig_header, endpoint_secret)
      rescue JSON::ParserError
        render json: { error: "Invalid payload", code: "bad_request" }, status: :bad_request
        return
      rescue Stripe::SignatureVerificationError
        render json: { error: "Invalid signature", code: "unauthorized" }, status: :unauthorized
        return
      end

      Billing::HandleWebhookEvent.new(event).call

      head_ok
    end
  end
end
