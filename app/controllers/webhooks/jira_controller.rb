class Webhooks::JiraController < Webhooks::BaseController
  def create
    account = find_account_from_params!
    payload = JSON.parse(@raw_body)

    # Jira webhooks don't have a standard signature — we rely on account_id + source being active
    normalized = Webhooks::JiraNormalizer.new(payload).normalize

    if normalized
      FeedbackIngestJob.perform_async(account.id, find_source_id(account, :jira), normalized)
    end

    render_accepted
  rescue JSON::ParserError
    render json: { error: "Invalid JSON" }, status: :bad_request
  end
end
