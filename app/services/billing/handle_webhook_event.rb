module Billing
  class HandleWebhookEvent
    PLAN_MAP = {
      ENV.fetch("STRIPE_STARTER_PRICE_ID", "price_starter_placeholder") => "starter",
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
      when "checkout.session.completed"
        handle_checkout_completed
      when "customer.subscription.updated"
        handle_subscription_updated
      when "customer.subscription.deleted"
        handle_subscription_deleted
      when "invoice.payment_failed"
        handle_payment_failed
      else
        Rails.logger.info("[Stripe Webhook] Unhandled event type: #{@type}")
      end
    end

    private

    def handle_checkout_completed
      account_id = @object.metadata["account_id"]
      return unless account_id

      account = Account.find_by(id: account_id)
      return unless account

      subscription = Stripe::Subscription.retrieve(@object.subscription)
      price_id = subscription.items.data.first.price.id
      plan = PLAN_MAP[price_id] || "starter"

      account.update!(
        stripe_customer_id: @object.customer,
        stripe_subscription_id: @object.subscription,
        plan: plan
      )

      Rails.logger.info("[Stripe] Account #{account_id} subscribed to #{plan}")
    end

    def handle_subscription_updated
      account = Account.find_by(stripe_subscription_id: @object.id)
      return unless account

      price_id = @object.items.data.first.price.id
      plan = PLAN_MAP[price_id]

      if plan && account.plan != plan
        account.update!(plan: plan)
        Rails.logger.info("[Stripe] Account #{account.id} plan changed to #{plan}")
      end
    end

    def handle_subscription_deleted
      account = Account.find_by(stripe_subscription_id: @object.id)
      return unless account

      account.update!(
        plan: :starter,
        stripe_subscription_id: nil
      )

      Rails.logger.info("[Stripe] Account #{account.id} subscription canceled, downgraded to starter")
    end

    def handle_payment_failed
      account = Account.find_by(stripe_customer_id: @object.customer)
      return unless account

      # TODO: Send payment failure notification email
      Rails.logger.warn("[Stripe] Payment failed for account #{account.id}")
    end
  end
end
