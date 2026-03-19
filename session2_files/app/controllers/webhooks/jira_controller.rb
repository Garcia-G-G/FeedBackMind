class Webhooks::JiraController < Webhooks::BaseController
  def create
    account = find_account_from_params!
    payload = JSON.parse(@raw_body)

    normalized = Webhooks::JiraNormalizer.new(payload).normalize

    if normalized
      FeedbackIngestJob.perform_async(account.id, find_source_id(account, :jira), normalized)
    end

    render_accepted
  rescue JSON::ParserError
    render json: { error: "Invalid JSON" }, status: :bad_request
  end

  private

  def find_account_from_params!
    Account.find(params.require(:account_id))
  end

  def find_source_id(account, type)
    account.sources.find_by!(source_type: type, active: true).id
  end
end
