module Billing
  class HandleWebhookEvent
    PLAN_MAP = {
      ENV.fetch("STRIPE_GROWTH_PRICE_ID", "price_growth_placeholder") => "growth",
      ENV.fetch("STRIPE_SCALE_PRICE_ID", "price_scale_placeholder") => "scale"
    }.freeze

    def initialize(event)
      @event = event
      @type = event.type
      @object = event.data.object
    end

    def call
      case @type
      when "customer.subscription.created", "customer.subscription.updated"
        handle_subscription_update
      when "customer.subscription.deleted"
        handle_subscription_deleted
      when "invoice.payment_failed"
        handle_payment_failed
      else
        Rails.logger.info("[Billing::HandleWebhookEvent] Unhandled event type: #{@type}")
      end
    end

    private

    def handle_subscription_update
      account = find_account
      return unless account

      price_id = @object.items.data.first&.price&.id
      plan = PLAN_MAP[price_id] || "starter"

      account.update!(
        stripe_subscription_id: @object.id,
        plan: plan
      )

      Rails.logger.info("[Billing] Account #{account.id} updated to #{plan} plan")
    end

    def handle_subscription_deleted
      account = find_account
      return unless account

      account.update!(
        stripe_subscription_id: nil,
        plan: :starter
      )

      Rails.logger.info("[Billing] Account #{account.id} downgraded to starter (subscription cancelled)")
    end

    def handle_payment_failed
      account = find_account
      return unless account

      Rails.logger.warn("[Billing] Payment failed for account #{account.id}")
      # TODO: Send payment failed notification email
    end

    def find_account
      customer_id = @object.customer
      account = Account.find_by(stripe_customer_id: customer_id)

      unless account
        Rails.logger.error("[Billing] No account found for Stripe customer #{customer_id}")
      end

      account
    end
  end
end
