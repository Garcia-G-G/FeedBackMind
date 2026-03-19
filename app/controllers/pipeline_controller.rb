class PipelineController < ApplicationController
  def show
    @raw_feedbacks = current_account.feedbacks
      .unprocessed
      .order(created_at: :desc)
      .limit(20)

    @processed_feedbacks = current_account.feedbacks
      .processed
      .order(created_at: :desc)
      .limit(20)

    @shipped = []
  end
end
