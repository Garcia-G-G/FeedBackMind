module Webhooks
  class IntercomController < BaseController
    before_action :verify_signature

    # POST /webhooks/intercom
    def create
      payload = JSON.parse(@raw_body)
      topic = payload["topic"]

      # Only process conversation-related events
      unless topic&.start_with?("conversation")
        head_ok
        return
      end

      account = Account.find_by!(subdomain: params[:account_subdomain])
      source = find_source(account, "intercom")

      normalized = Webhooks::IntercomNormalizer.new(payload).normalize
      enqueue_feedback(account.id, source.id, normalized) if normalized

      head_ok
    end

    private

    def verify_signature
      secret = ENV.fetch("INTERCOM_WEBHOOK_SECRET", nil)
      return if secret.blank? # Skip verification if no secret configured

      signature = request.headers["X-Hub-Signature"]
      return render_unauthorized unless signature

      computed = "sha1=#{OpenSSL::HMAC.hexdigest('SHA256', secret, @raw_body)}"
      verify_signature_or_reject!(computed, signature)
    end

    def render_unauthorized
      render json: { error: "Missing signature", code: "unauthorized" }, status: :unauthorized
    end
  end
end
