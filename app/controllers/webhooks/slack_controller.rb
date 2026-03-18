module Webhooks
  class SlackController < BaseController
    before_action :verify_signature

    # POST /webhooks/slack
    def create
      payload = JSON.parse(@raw_body)

      # Handle Slack URL verification challenge
      if payload["type"] == "url_verification"
        render json: { challenge: payload["challenge"] }
        return
      end

      return head_ok unless payload["type"] == "event_callback"

      event = payload["event"]
      return head_ok unless event && event["type"] == "message" && event["subtype"].nil?

      team_id = payload["team_id"]
      source = Source.find_by!(source_type: :slack, active: true, config: { "team_id" => team_id }.as_json)
      account = source.account

      normalized = Webhooks::SlackNormalizer.new(payload).normalize
      enqueue_feedback(account.id, source.id, normalized) if normalized

      head_ok
    end

    private

    def verify_signature
      secret = ENV.fetch("SLACK_SIGNING_SECRET", nil)
      return if secret.blank?

      timestamp = request.headers["X-Slack-Request-Timestamp"]
      slack_signature = request.headers["X-Slack-Signature"]

      return render_unauthorized unless timestamp && slack_signature

      # Reject requests older than 5 minutes
      if (Time.now.to_i - timestamp.to_i).abs > 300
        render json: { error: "Request too old", code: "unauthorized" }, status: :unauthorized
        return
      end

      sig_basestring = "v0:#{timestamp}:#{@raw_body}"
      computed = "v0=#{OpenSSL::HMAC.hexdigest('SHA256', secret, sig_basestring)}"
      verify_signature_or_reject!(computed, slack_signature)
    end

    def render_unauthorized
      render json: { error: "Missing signature headers", code: "unauthorized" }, status: :unauthorized
    end
  end
end
