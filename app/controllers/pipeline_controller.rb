class PipelineController < ApplicationController
  def show
    @raw_feedbacks = current_account.feedbacks.unprocessed.order(created_at: :desc).limit(20)
    @processed_feedbacks = current_account.feedbacks.processed.order(processed_at: :desc).limit(20)
    @raw_count = current_account.feedbacks.unprocessed.count
    @processed_count = current_account.feedbacks.processed.count
    @themes = current_account.weekly_syntheses.order(week_start: :desc).first&.themes || []
  end
end
