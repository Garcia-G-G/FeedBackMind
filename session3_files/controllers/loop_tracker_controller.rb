class LoopTrackerController < ApplicationController
  def show
    @resolved_themes = current_account.feedbacks
      .where(status: :resolved)
      .group_by(&:topic)
      .transform_values(&:count)

    @closed_loop_feedbacks = current_account.feedbacks
      .where(status: :resolved)
      .order(resolved_at: :desc)
      .limit(20)
  end
end
