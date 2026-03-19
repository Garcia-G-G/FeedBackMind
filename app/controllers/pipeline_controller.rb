class PipelineController < ApplicationController
  def show
    @raw_feedbacks = current_account.feedbacks
      .unprocessed
      .order(created_at: :desc)
      .limit(20)

    @insights = current_account.feedbacks
      .processed
      .group_by(&:topic)

    @shipped = []
  end
end
