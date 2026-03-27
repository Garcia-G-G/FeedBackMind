module Api
  module V1
    class NpsController < ActionController::API
      include NpsCors

      def config
        survey = NpsSurvey.find_by!(survey_token: params[:token])
        render json: {
          question: survey.question,
          followup_question: survey.followup_question,
          thank_you_message: survey.thank_you_message,
          brand_color: survey.brand_color,
          position: survey.position
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Survey not found" }, status: :not_found
      end

      def respond_survey
        survey = NpsSurvey.find_by!(survey_token: params[:token])

        unless survey.active?
          render json: { error: "Survey is not active" }, status: :gone
          return
        end

        ActsAsTenant.current_tenant = survey.account

        nps_response = survey.nps_responses.create!(
          account: survey.account,
          score: params[:score].to_i,
          comment: params[:comment],
          respondent_email: params[:email],
          respondent_name: params[:name],
          respondent_id: params[:user_id],
          page_url: params[:page_url]
        )

        # Create feedback via ingest job
        source = survey.account.sources.find_or_create_by!(source_type: :nps) do |s|
          s.active = true
          s.config = {}
        end

        content_parts = ["NPS Score: #{nps_response.score}/10"]
        content_parts << nps_response.comment if nps_response.comment.present?
        content = content_parts.join(" — ")

        FeedbackIngestJob.perform_async(
          survey.account.id,
          source.id,
          {
            "external_id" => "nps_#{nps_response.id}",
            "content" => content,
            "author_name" => nps_response.respondent_name,
            "author_email" => nps_response.respondent_email,
            "metadata" => {
              "nps_score" => nps_response.score,
              "category" => nps_response.category,
              "survey_id" => survey.id,
              "survey_name" => survey.name,
              "page_url" => nps_response.page_url
            },
            "received_at" => Time.current.iso8601
          }
        )

        render json: { success: true, message: survey.thank_you_message }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Survey not found" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
