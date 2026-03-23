require "rails_helper"

RSpec.describe "Webhooks::Intercom", type: :request do
  let(:account) { create(:account) }
  let!(:source) { create(:source, account: account, source_type: :intercom, active: true, config: {}) }

  let(:valid_payload) do
    {
      topic: "conversation.user.created",
      data: {
        item: {
          id: "conv_123",
          source: { body: "<p>Your onboarding is confusing</p>" },
          user: { email: "user@example.com", name: "Jane Doe" },
          tags: { tags: [{ name: "feedback" }] },
          created_at: Time.current.to_i
        }
      }
    }.to_json
  end

  it "accepts valid webhook and enqueues job" do
    expect {
      post "/webhooks/intercom/#{account.id}",
           params: valid_payload,
           headers: { "Content-Type" => "application/json" }
    }.to change(FeedbackIngestJob.jobs, :size).by(1)

    expect(response).to have_http_status(:ok)
  end

  it "returns 400 for invalid JSON" do
    post "/webhooks/intercom/#{account.id}",
         params: "not json",
         headers: { "Content-Type" => "application/json" }

    expect(response).to have_http_status(:bad_request)
  end
end
