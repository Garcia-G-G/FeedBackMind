class Webhooks::StripeController < Webhooks::BaseController
  def create
    event = construct_stripe_event
    return render_unauthorized unless event

    Billing::HandleWebhookEvent.new(event).call

    render_accepted
  end

  private

  def construct_stripe_event
    Stripe::Webhook.construct_event(
      @raw_body,
      request.headers["Stripe-Signature"],
      Rails.application.credentials.dig(:stripe, :webhook_secret) || ENV.fetch("STRIPE_WEBHOOK_SECRET")
    )
  rescue Stripe::SignatureVerificationError => e
    Rails.logger.warn("[Stripe Webhook] Signature verification failed: #{e.message}")
    nil
  rescue JSON::ParserError
    Rails.logger.warn("[Stripe Webhook] Invalid JSON payload")
    nil
  end
end
