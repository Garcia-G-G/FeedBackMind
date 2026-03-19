require "rails_helper"

RSpec.describe "Webhooks::Stripe", type: :request do
  it "returns unauthorized with invalid signature" do
    post "/webhooks/stripe",
         params: { type: "checkout.session.completed" }.to_json,
         headers: {
           "Content-Type" => "application/json",
           "Stripe-Signature" => "invalid_signature"
         }

    expect(response).to have_http_status(:unauthorized)
  end
end
