require "rails_helper"

RSpec.describe "Webhooks::Slack", type: :request do
  let(:account) { create(:account) }
  let!(:source) { create(:source, account: account, source_type: :slack, active: true, config: {}) }

  it "responds to Slack URL verification challenge" do
    post "/webhooks/slack?account_id=#{account.id}",
         params: { type: "url_verification", challenge: "test_challenge_token" }.to_json,
         headers: { "Content-Type" => "application/json" }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["challenge"]).to eq("test_challenge_token")
  end

  it "processes message events" do
    payload = {
      type: "event_callback",
      event: {
        type: "message",
        text: "The dashboard is really slow today",
        user: "U12345",
        channel: "C67890",
        ts: Time.current.to_f.to_s
      }
    }.to_json

    expect {
      post "/webhooks/slack?account_id=#{account.id}",
           params: payload,
           headers: { "Content-Type" => "application/json" }
    }.to change(FeedbackIngestJob.jobs, :size).by(1)

    expect(response).to have_http_status(:ok)
  end
end
