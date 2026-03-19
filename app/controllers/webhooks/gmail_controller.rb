class Webhooks::GmailController < Webhooks::BaseController
  def create
    account = find_account_from_params!
    payload = JSON.parse(@raw_body)

    normalized = Webhooks::GmailNormalizer.new(payload).normalize

    if normalized
      FeedbackIngestJob.perform_async(account.id, find_source_id(account, :gmail), normalized)
    end

    render_accepted
  rescue JSON::ParserError
    render json: { error: "Invalid JSON" }, status: :bad_request
  end
end
