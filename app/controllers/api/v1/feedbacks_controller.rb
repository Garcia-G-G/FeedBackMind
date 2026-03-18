module Api
  module V1
    class FeedbacksController < BaseController
      # GET /api/v1/feedbacks
      def index
        feedbacks = current_account.feedbacks.recent

        # Filters
        feedbacks = feedbacks.by_sentiment(params[:sentiment]) if params[:sentiment].present?
        feedbacks = feedbacks.by_topic(params[:topic]) if params[:topic].present?
        feedbacks = feedbacks.from_source_type(params[:source_type]) if params[:source_type].present?
        feedbacks = feedbacks.where(source_id: params[:source_id]) if params[:source_id].present?
        feedbacks = feedbacks.unprocessed if params[:unprocessed] == "true"
        feedbacks = feedbacks.processed if params[:processed] == "true"

        if params[:since].present?
          feedbacks = feedbacks.where("received_at >= ?", Time.parse(params[:since]))
        end

        render json: {
          feedbacks: paginate(feedbacks).map { |f| feedback_json(f) },
          meta: pagination_meta(feedbacks)
        }
      end

      # GET /api/v1/feedbacks/:id
      def show
        feedback = current_account.feedbacks.find(params[:id])
        render json: feedback_json(feedback)
      end

      # POST /api/v1/feedbacks/import_csv
      def import_csv
        unless params[:file].present?
          render json: { error: "CSV file required", code: "missing_parameter" }, status: :unprocessable_entity
          return
        end

        result = ::Feedback::CsvImporter.new(
          account: current_account,
          source_id: params[:source_id]
        ).import(params[:file])

        render json: result, status: :created
      end

      private

      def feedback_json(feedback)
        {
          id: feedback.id,
          source_id: feedback.source_id,
          external_id: feedback.external_id,
          content: feedback.content,
          author_email: feedback.author_email,
          author_name: feedback.author_name,
          sentiment: feedback.sentiment,
          topics: feedback.topics,
          metadata: feedback.metadata,
          received_at: feedback.received_at,
          processed_at: feedback.processed_at,
          created_at: feedback.created_at
        }
      end
    end
  end
end
