class FeedbacksController < ApplicationController
  before_action :set_feedback, only: [:show]

  def index
    @feedbacks = current_account.feedbacks.includes(:source).order(received_at: :desc)

    # Filters
    @feedbacks = @feedbacks.where(sentiment: params[:sentiment]) if params[:sentiment].present?
    @feedbacks = @feedbacks.joins(:source).where(sources: { source_type: params[:source_type] }) if params[:source_type].present?
    @feedbacks = @feedbacks.where("feedbacks.content ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    @feedbacks = @feedbacks.unprocessed if params[:status] == "unprocessed"
    @feedbacks = @feedbacks.processed if params[:status] == "processed"
    @feedbacks = @feedbacks.where(company_id: params[:company_id]) if params[:company_id].present?

    # Sort
    if params[:sort] == "priority"
      @feedbacks = @feedbacks.reorder(Arel.sql("priority_score DESC NULLS LAST"))
    end

    # Pagination
    @page = [params[:page].to_i, 1].max
    @per_page = 20
    @total_count = @feedbacks.count
    @feedbacks = @feedbacks.offset((@page - 1) * @per_page).limit(@per_page)
  end

  def show
    if @feedback.has_embedding?
      @related_feedbacks = current_account.feedbacks
                               .where.not(id: @feedback.id)
                               .nearest_to(@feedback.embedding, limit: 3)
    end
  end

  private

  def set_feedback
    @feedback = current_account.feedbacks.find(params[:id])
  end
end
