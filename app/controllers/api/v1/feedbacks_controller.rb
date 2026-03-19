class Api::V1::FeedbacksController < Api::V1::BaseController
  def index
    feedbacks = current_account.feedbacks.includes(:source).recent

    # Filters
    feedbacks = feedbacks.by_sentiment(params[:sentiment]) if params[:sentiment].present?
    feedbacks = feedbacks.by_topic(params[:topic]) if params[:topic].present?
    feedbacks = feedbacks.from_source_type(params[:source_type]) if params[:source_type].present?
    feedbacks = feedbacks.where(source_id: params[:source_id]) if params[:source_id].present?
    feedbacks = feedbacks.unprocessed if params[:unprocessed] == "true"
    feedbacks = feedbacks.processed if params[:processed] == "true"

    # Date range filter
    if params[:since].present?
      feedbacks = feedbacks.where("received_at >= ?", Time.parse(params[:since]))
    end
    if params[:until].present?
      feedbacks = feedbacks.where("received_at <= ?", Time.parse(params[:until]))
    end

    total_scope = feedbacks
    feedbacks = paginate(feedbacks)

    render json: {
      feedbacks: feedbacks.map { |f| feedback_json(f) },
      meta: pagination_meta(total_scope)
    }
  end

  def show
    feedback = current_account.feedbacks.find(params[:id])
    render json: { feedback: feedback_json(feedback, detailed: true) }
  end

  def import_csv
    file = params[:file]

    unless file.present? && file.content_type.in?(%w[text/csv application/csv text/plain])
      return render json: { error: "Please upload a valid CSV file", code: "invalid_file" }, status: :unprocessable_entity
    end

    source = current_account.sources.find_or_create_by!(source_type: :csv) do |s|
      s.active = true
    end

    result = Feedbacks::CsvImporter.new(
      account: current_account,
      source: source,
      file: file
    ).import

    render json: {
      message: "CSV import started",
      rows_enqueued: result[:enqueued],
      rows_skipped: result[:skipped],
      errors: result[:errors]
    }, status: :accepted
  end

  private

  def feedback_json(feedback, detailed: false)
    json = {
      id: feedback.id,
      source_type: feedback.source.source_type,
      content: feedback.content.truncate(300),
      sentiment: feedback.sentiment,
      topics: feedback.topics,
      author_name: feedback.author_name,
      received_at: feedback.received_at,
      processed: feedback.processed?
    }

    if detailed
      json[:content] = feedback.content # Full content
      json[:author_email] = feedback.author_email
      json[:metadata] = feedback.metadata
      json[:source_id] = feedback.source_id
      json[:external_id] = feedback.external_id
      json[:processed_at] = feedback.processed_at
    end

    json
  end
end
