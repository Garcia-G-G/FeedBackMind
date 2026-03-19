class Webhooks::SlackController < Webhooks::BaseController
  def create
    payload = JSON.parse(@raw_body)

    if payload["type"] == "url_verification"
      return render json: { challenge: payload["challenge"] }
    end

    account = find_account_from_params!

    unless verify_slack_signature(account)
      return render_unauthorized
    end

    normalized = Webhooks::SlackNormalizer.new(payload).normalize

    if normalized
      FeedbackIngestJob.perform_async(account.id, find_source_id(account, :slack), normalized)
    end

    render_accepted
  rescue JSON::ParserError
    render json: { error: "Invalid JSON" }, status: :bad_request
  end

  private

  def verify_slack_signature(account)
    secret = account.sources.find_by(source_type: :slack)&.config&.dig("signing_secret")
    return true unless secret

    timestamp = request.headers["X-Slack-Request-Timestamp"]
    return false unless timestamp
    return false if (Time.now.to_i - timestamp.to_i).abs > 300

    sig_basestring = "v0:#{timestamp}:#{@raw_body}"
    expected = "v0=" + OpenSSL::HMAC.hexdigest("SHA256", secret, sig_basestring)
    signature = request.headers["X-Slack-Signature"]

    ActiveSupport::SecurityUtils.secure_compare(expected, signature.to_s)
  end

  def find_account_from_params!
    Account.find(params.require(:account_id))
  end

  def find_source_id(account, type)
    account.sources.find_by!(source_type: type, active: true).id
  end
end
