module Webhooks
  class TypeformController < BaseController
    before_action :verify_signature

    # POST /webhooks/typeform
    def create
      payload = JSON.parse(@raw_body)

      account = Account.find_by!(subdomain: params[:account_subdomain])
      source = find_source(account, "typeform")

      normalized = Webhooks::TypeformNormalizer.new(payload).normalize
      enqueue_feedback(account.id, source.id, normalized) if normalized

      head_ok
    end

    private

    def verify_signature
      secret = ENV.fetch("TYPEFORM_WEBHOOK_SECRET", nil)
      return if secret.blank?

      signature = request.headers["Typeform-Signature"]
      return render_unauthorized unless signature

      computed = "sha256=#{Base64.encode64(OpenSSL::HMAC.digest('SHA256', secret, @raw_body)).strip}"
      verify_signature_or_reject!(computed, signature)
    end

    def render_unauthorized
      render json: { error: "Missing signature", code: "unauthorized" }, status: :unauthorized
    end
  end
end
