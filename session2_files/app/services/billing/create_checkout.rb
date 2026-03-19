module Billing
  class CreateCheckout
    PRICE_IDS = {
      "starter" => ENV.fetch("STRIPE_STARTER_PRICE_ID", "price_starter_placeholder"),
      "growth"  => ENV.fetch("STRIPE_GROWTH_PRICE_ID", "price_growth_placeholder"),
      "scale"   => ENV.fetch("STRIPE_SCALE_PRICE_ID", "price_scale_placeholder")
    }.freeze

    def initialize(account:, plan:, success_url:, cancel_url:)
      @account = account
      @plan = plan
      @success_url = success_url
      @cancel_url = cancel_url
    end

    def call
      customer_id = find_or_create_stripe_customer

      session = Stripe::Checkout::Session.create(
        customer: customer_id,
        mode: "subscription",
        line_items: [{
          price: PRICE_IDS[@plan],
          quantity: 1
        }],
        success_url: @success_url,
        cancel_url: @cancel_url,
        metadata: {
          account_id: @account.id,
          plan: @plan
        }
      )

      { checkout_url: session.url, session_id: session.id }
    end

    private

    def find_or_create_stripe_customer
      if @account.stripe_customer_id.present?
        @account.stripe_customer_id
      else
        customer = Stripe::Customer.create(
          name: @account.name,
          email: @account.users.find_by(role: :owner)&.email,
          metadata: { account_id: @account.id }
        )
        @account.update!(stripe_customer_id: customer.id)
        customer.id
      end
    end
  end
end
