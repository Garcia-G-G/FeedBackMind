module Billing
  class CreateCheckout
    PRICE_IDS = {
      "growth" => ENV.fetch("STRIPE_GROWTH_PRICE_ID", "price_growth_placeholder"),
      "scale" => ENV.fetch("STRIPE_SCALE_PRICE_ID", "price_scale_placeholder")
    }.freeze

    def initialize(account:, plan:, success_url:, cancel_url:)
      @account = account
      @plan = plan
      @success_url = success_url
      @cancel_url = cancel_url
    end

    def call
      price_id = PRICE_IDS[@plan]
      raise ArgumentError, "Invalid plan: #{@plan}" unless price_id

      # Create or reuse Stripe customer
      customer_id = @account.stripe_customer_id || create_customer

      Stripe::Checkout::Session.create(
        customer: customer_id,
        mode: "subscription",
        line_items: [{ price: price_id, quantity: 1 }],
        success_url: @success_url,
        cancel_url: @cancel_url,
        metadata: { account_id: @account.id }
      )
    end

    private

    def create_customer
      customer = Stripe::Customer.create(
        name: @account.name,
        metadata: { account_id: @account.id, subdomain: @account.subdomain }
      )
      @account.update!(stripe_customer_id: customer.id)
      customer.id
    end
  end
end
