class FeedbacksController < ApplicationController
  before_action :set_feedback, only: [:show]

  def index
    @feedbacks = apply_filters(current_account.feedbacks.includes(:source))
    @feedbacks = @feedbacks.order(created_at: :desc)

    apply_pagination
  end

  def show
  end

  private

  def set_feedback
    @feedback = current_account.feedbacks.find(params[:id])
  end

  def apply_filters(feedbacks)
    feedbacks = feedbacks.where(sentiment: params[:sentiment]) if params[:sentiment].present?
    feedbacks = feedbacks.where(sources: { source_type: params[:source_type] }) if params[:source_type].present?
    feedbacks = feedbacks.where('content ILIKE ?', "%#{params[:topic]}%") if params[:topic].present?
    feedbacks
  end

  def apply_pagination
    page = params[:page] || 1
    limit = params[:limit] || 20
    offset = (page.to_i - 1) * limit.to_i

    @feedbacks = @feedbacks.offset(offset).limit(limit)
  end
end
