class LoopTrackerController < ApplicationController
  def show
    @shipped_count = 0
    @in_progress_count = current_account.feedbacks.unprocessed.count
    @total_feedbacks = current_account.feedbacks.count
    @processed_feedbacks = current_account.feedbacks.processed.count
  end
end
