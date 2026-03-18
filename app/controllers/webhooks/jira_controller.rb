module Webhooks
  class JiraController < BaseController
    before_action :verify_signature

    # POST /webhooks/jira
    def create
      payload = JSON.parse(@raw_body)

      # Only process issue comment events
      webhook_event = payload["webhookEvent"]
      unless webhook_event&.include?("comment")
        head_ok
        return
      end

      account = Account.find_by!(subdomain: params[:account_subdomain])
      source = find_source(account, "jira")

      normalized = Webhooks::JiraNormalizer.new(payload).normalize
      enqueue_feedback(account.id, source.id, normalized) if normalized

      head_ok
    end

    private

    def verify_signature
      secret = ENV.fetch("JIRA_WEBHOOK_SECRET", nil)
      return if secret.blank?

      # Jira can use HMAC-SHA256 or IP allowlist
      signature = request.headers["X-Hub-Signature"]
      return if signature.blank? # Fall through if using IP allowlist

      computed = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, @raw_body)}"
      verify_signature_or_reject!(computed, signature)
    end
  end
end
