module Api
  module V1
    class SynthesesController < BaseController
      # GET /api/v1/syntheses
      def index
        syntheses = current_account.weekly_syntheses.recent

        render json: {
          syntheses: paginate(syntheses).map { |s| synthesis_json(s) },
          meta: pagination_meta(syntheses)
        }
      end

      # GET /api/v1/syntheses/:id
      def show
        synthesis = current_account.weekly_syntheses.find(params[:id])
        render json: synthesis_json(synthesis, detailed: true)
      end

      # GET /api/v1/syntheses/latest
      def latest
        synthesis = current_account.weekly_syntheses.recent.first
        if synthesis
          render json: synthesis_json(synthesis, detailed: true)
        else
          render json: { error: "No syntheses found", code: "not_found" }, status: :not_found
        end
      end

      private

      def synthesis_json(synthesis, detailed: false)
        base = {
          id: synthesis.id,
          week_start: synthesis.week_start,
          week_label: synthesis.week_label,
          feedback_count: synthesis.feedback_count,
          executive_summary: synthesis.executive_summary,
          sent_at: synthesis.sent_at,
          created_at: synthesis.created_at
        }

        if detailed
          base.merge(
            top_themes: synthesis.top_themes,
            biggest_risk: synthesis.biggest_risk,
            quick_wins: synthesis.quick_wins
          )
        else
          base
        end
      end
    end
  end
end
