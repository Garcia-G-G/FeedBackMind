class FeatureRequestsController < ApplicationController
  before_action :set_feature_request, only: [:show, :edit, :update, :destroy, :publish, :unpublish, :merge, :link_feedback, :unlink_feedback]

  def index
    scope = current_account.feature_requests.not_merged

    scope = scope.search(params[:q]) if params[:q].present?
    scope = scope.by_status(params[:status]) if params[:status].present?
    scope = scope.by_category(params[:category]) if params[:category].present?

    case params[:visibility]
    when "published" then scope = scope.published
    when "draft" then scope = scope.draft
    end

    @feature_requests = case params[:sort]
                        when "recent" then scope.by_recent
                        when "oldest" then scope.order(created_at: :asc)
                        else scope.by_votes.by_recent
                        end

    @status_counts = current_account.feature_requests.not_merged.group(:status).count
    @total_count = current_account.feature_requests.not_merged.count
  end

  def show
    @linked_feedbacks = @feature_request.feedbacks.includes(:source).order(received_at: :desc)
    @recent_voters = @feature_request.votes.order(created_at: :desc).limit(10)
    @available_feedbacks = current_account.feedbacks.includes(:source)
                               .where.not(id: @linked_feedbacks.select(:id))
                               .order(received_at: :desc).limit(20)
    @merge_candidates = current_account.feature_requests.not_merged
                             .where.not(id: @feature_request.id)
                             .by_votes.limit(20)
  end

  def new
    @feature_request = current_account.feature_requests.new(
      author_name: current_user.display_name,
      author_email: current_user.email
    )
  end

  def create
    @feature_request = current_account.feature_requests.new(feature_request_params)
    @feature_request.user = current_user
    @feature_request.author_name ||= current_user.display_name
    @feature_request.author_email ||= current_user.email

    if @feature_request.save
      redirect_to @feature_request, notice: "Feature request created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @feature_request.update(feature_request_params)
      redirect_to @feature_request, notice: "Feature request updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @feature_request.destroy
    redirect_to feature_requests_path, notice: "Feature request deleted."
  end

  def publish
    @feature_request.publish!
    redirect_to @feature_request, notice: "Feature request published to portal."
  end

  def unpublish
    @feature_request.unpublish!
    redirect_to @feature_request, notice: "Feature request unpublished."
  end

  def merge
    target = current_account.feature_requests.find(params[:target_id])
    @feature_request.merge_into!(target)
    redirect_to target, notice: "\"#{@feature_request.title}\" merged into \"#{target.title}\"."
  end

  def link_feedback
    feedback = current_account.feedbacks.find(params[:feedback_id])
    @feature_request.feature_request_feedbacks.find_or_create_by!(feedback: feedback)
    redirect_to @feature_request, notice: "Feedback linked."
  end

  def unlink_feedback
    feedback = current_account.feedbacks.find(params[:feedback_id])
    @feature_request.feature_request_feedbacks.find_by(feedback: feedback)&.destroy
    redirect_to @feature_request, notice: "Feedback unlinked."
  end

  private

  def set_feature_request
    @feature_request = current_account.feature_requests.find(params[:id])
  end

  def feature_request_params
    params.require(:feature_request).permit(:title, :description, :status, :category, :author_name, :author_email, :admin_notes)
  end
end
