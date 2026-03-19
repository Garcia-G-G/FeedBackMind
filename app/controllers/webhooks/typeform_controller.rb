class Webhooks::TypeformController < Webhooks::BaseController
  def create
    account = find_account_from_params!

    unless verify_typeform_signature(account)
      return render_unauthorized
    end

    payload = JSON.parse(@raw_body)
    normalized = Webhooks::TypeformNormalizer.new(payload).normalize

    if normalized
      FeedbackIngestJob.perform_async(account.id, find_source_id(account, :typeform), normalized)
    end

    render_accepted
  rescue JSON::ParserError
    render json: { error: "Invalid JSON" }, status: :bad_request
  end

  private

  def verify_typeform_signature(account)
    secret = account.sources.find_by(source_type: :typeform)&.config&.dig("webhook_secret")
    return true unless secret

    expected = OpenSSL::HMAC.digest("SHA256", secret, @raw_body)
    signature = Base64.decode64(request.headers["Typeform-Signature"].to_s.sub("sha256=", ""))

    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end
end
