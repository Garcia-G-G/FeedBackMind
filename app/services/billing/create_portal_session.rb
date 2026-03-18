module Billing
  class CreatePortalSession
    def initialize(account:, return_url:)
      @account = account
      @return_url = return_url
    end

    def call
      unless @account.stripe_customer_id
        raise "No Stripe customer found for account #{@account.id}. Customer must complete checkout first."
      end

      Stripe::BillingPortal::Session.create(
        customer: @account.stripe_customer_id,
        return_url: @return_url
      )
    end
  end
end
