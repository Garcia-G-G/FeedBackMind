module Webhooks
  class GmailController < BaseController
    # POST /webhooks/gmail
    # Receives forwarded emails via Cloudflare Email Routing or Google Pub/Sub
    def create
      payload = JSON.parse(@raw_body)

      account = Account.find_by!(subdomain: params[:account_subdomain])
      source = find_source(account, "gmail")

      normalized = Webhooks::GmailNormalizer.new(payload).normalize
      enqueue_feedback(account.id, source.id, normalized) if normalized

      head_ok
    end
  end
end
