class Api::V1::SynthesesController < Api::V1::BaseController
  def index
    syntheses = current_account.weekly_syntheses.recent
    syntheses = paginate(syntheses)

    render json: {
      syntheses: syntheses.map { |s| synthesis_json(s) }
    }
  end

  def show
    synthesis = current_account.weekly_syntheses.find(params[:id])

    render json: {
      synthesis: synthesis_json(synthesis, detailed: true)
    }
  end

  private

  def synthesis_json(synthesis, detailed: false)
    json = {
      id: synthesis.id,
      week_label: synthesis.week_label,
      week_start: synthesis.week_start,
      feedback_count: synthesis.feedback_count,
      sent: synthesis.sent?,
      created_at: synthesis.created_at
    }

    if detailed
      json[:top_themes] = synthesis.top_themes
      json[:executive_summary] = synthesis.executive_summary
      json[:biggest_risk] = synthesis.biggest_risk
      json[:quick_wins] = synthesis.quick_wins
      json[:sent_at] = synthesis.sent_at
    end

    json
  end
end
