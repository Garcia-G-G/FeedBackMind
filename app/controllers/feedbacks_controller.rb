class FeedbacksController < ApplicationController
  before_action :set_feedback, only: [:show, :add_tag, :remove_tag]

  def index
    @feedbacks = current_account.feedbacks.includes(:source, :company).order(received_at: :desc)

    # Filters
    @feedbacks = @feedbacks.where(sentiment: params[:sentiment]) if params[:sentiment].present?
    @feedbacks = @feedbacks.joins(:source).where(sources: { source_type: params[:source_type] }) if params[:source_type].present?
    @feedbacks = @feedbacks.where("feedbacks.content ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    @feedbacks = @feedbacks.unprocessed if params[:status] == "unprocessed"
    @feedbacks = @feedbacks.processed if params[:status] == "processed"
    @feedbacks = @feedbacks.where(company_id: params[:company_id]) if params[:company_id].present?
    @feedbacks = @feedbacks.by_tag(params[:tag]) if params[:tag].present?

    # Sort
    if params[:sort] == "priority"
      @feedbacks = @feedbacks.reorder(Arel.sql("priority_score DESC NULLS LAST"))
    end

    # Saved views
    @saved_views = current_account.saved_views.where(user: current_user).ordered

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

  def export
    feedbacks = current_account.feedbacks.includes(:source, :company).order(received_at: :desc)
    feedbacks = feedbacks.where(sentiment: params[:sentiment]) if params[:sentiment].present?
    feedbacks = feedbacks.where(company_id: params[:company_id]) if params[:company_id].present?

    csv_data = CSV.generate(headers: true) do |csv|
      csv << ["ID", "Content", "Sentiment", "Priority Score", "Priority Label", "Source", "Author Name", "Author Email", "Company", "Topics", "Tags", "Received At"]
      feedbacks.find_each do |fb|
        csv << [
          fb.id,
          fb.content,
          fb.sentiment,
          fb.priority_score,
          fb.priority_label,
          fb.source&.source_type,
          fb.author_name,
          fb.author_email,
          fb.company&.name,
          fb.topics&.join(", "),
          fb.tags&.join(", "),
          fb.received_at&.iso8601
        ]
      end
    end

    send_data csv_data, filename: "feedbacks-#{Date.current}.csv", type: "text/csv"
  end

  def add_tag
    tag = params[:tag]&.strip&.downcase
    if tag.present? && !@feedback.tags.include?(tag)
      @feedback.update!(tags: @feedback.tags + [tag])
    end
    redirect_to feedback_path(@feedback)
  end

  def remove_tag
    tag = params[:tag]
    @feedback.update!(tags: @feedback.tags - [tag])
    redirect_to feedback_path(@feedback)
  end

  private

  def set_feedback
    @feedback = current_account.feedbacks.find(params[:id])
  end
end
