class LoopTrackerController < ApplicationController
  def show
    @total_feedbacks = current_account.feedbacks.count
    @processed_count = current_account.feedbacks.processed.count
    @unprocessed_count = current_account.feedbacks.unprocessed.count
    @syntheses_count = current_account.weekly_syntheses.count

    # Top topics across all processed feedbacks
    @top_topics = current_account.feedbacks.processed
      .pluck(:topics).flatten.compact
      .tally.sort_by { |_, count| -count }.first(10)

    @recent_syntheses = current_account.weekly_syntheses.order(week_start: :desc).limit(5)
  end
end
