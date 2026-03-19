class Webhooks::IntercomController < Webhooks::BaseController
  def create
    account = find_account_from_params!

    unless verify_intercom_signature(account)
      return render_unauthorized
    end

    payload = JSON.parse(@raw_body)
    normalized = Webhooks::IntercomNormalizer.new(payload).normalize

    if normalized
      FeedbackIngestJob.perform_async(account.id, find_source_id(account, :intercom), normalized)
    end

    render_accepted
  rescue JSON::ParserError
    render json: { error: "Invalid JSON" }, status: :bad_request
  end

  private

  def verify_intercom_signature(account)
    secret = account.sources.find_by(source_type: :intercom)&.config&.dig("webhook_secret")
    return true unless secret

    expected = OpenSSL::HMAC.hexdigest("SHA256", secret, @raw_body)
    signature = request.headers["X-Hub-Signature"]

    return false unless signature
    ActiveSupport::SecurityUtils.secure_compare("sha256=#{expected}", signature)
  end

  def find_account_from_params!
    Account.find(params.require(:account_id))
  end

  def find_source_id(account, type)
    account.sources.find_by!(source_type: type, active: true).id
  end
end
