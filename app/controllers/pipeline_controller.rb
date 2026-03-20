class PipelineController < ApplicationController
  def show
    @raw_feedbacks = current_account.feedbacks.unprocessed.order(created_at: :desc).limit(20)
    @processed_feedbacks = current_account.feedbacks.processed.order(processed_at: :desc).limit(20)
    @raw_count = current_account.feedbacks.unprocessed.count
    @processed_count = current_account.feedbacks.processed.count

    # Themes from latest synthesis
    @themes = current_account.weekly_syntheses.order(week_start: :desc).first&.themes || []

    # Pipeline columns derived from themes by urgency
    @insights = @themes.select { |t| t.respond_to?(:urgency) ? %w[high critical].include?(t.urgency) : false }
    @actions = @themes.select { |t| t.respond_to?(:urgency) ? t.urgency == "medium" : false }
    @shipped = @themes.select { |t| t.respond_to?(:urgency) ? t.urgency == "low" : false }
  end
end
