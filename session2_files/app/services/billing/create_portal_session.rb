module Billing
  class CreatePortalSession
    def initialize(account:, return_url:)
      @account = account
      @return_url = return_url
    end

    def call
      unless @account.stripe_customer_id.present?
        raise "Account does not have a Stripe customer. Complete checkout first."
      end

      session = Stripe::BillingPortal::Session.create(
        customer: @account.stripe_customer_id,
        return_url: @return_url
      )

      { portal_url: session.url }
    end
  end
end
