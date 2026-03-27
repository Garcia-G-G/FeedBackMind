class ChangelogEntriesController < ApplicationController
  before_action :set_entry, only: [:show, :edit, :update, :destroy, :publish, :unpublish, :link_feature_request, :unlink_feature_request]

  def index
    scope = current_account.changelog_entries

    case params[:visibility]
    when "published" then scope = scope.published
    when "draft" then scope = scope.draft
    else scope = scope.order(created_at: :desc)
    end

    scope = scope.by_category(params[:category]) if params[:category].present?

    @entries = scope
    @published_count = current_account.changelog_entries.published.count
    @draft_count = current_account.changelog_entries.draft.count
    @total_count = current_account.changelog_entries.count
  end

  def show
    @linked_feature_requests = @entry.feature_requests.by_votes
    @available_feature_requests = current_account.feature_requests
                                       .where(status: :shipped)
                                       .where.not(id: @linked_feature_requests.select(:id))
                                       .by_votes.limit(20)
  end

  def new
    @entry = current_account.changelog_entries.new
  end

  def create
    @entry = current_account.changelog_entries.new(entry_params)
    @entry.user = current_user

    if @entry.save
      redirect_to changelog_entry_path(@entry), notice: "Changelog entry created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @entry.update(entry_params)
      redirect_to changelog_entry_path(@entry), notice: "Changelog entry updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @entry.destroy
    redirect_to changelog_entries_path, notice: "Changelog entry deleted."
  end

  def publish
    @entry.publish!
    redirect_to changelog_entry_path(@entry), notice: "Published! Linked feature requests marked as shipped."
  end

  def unpublish
    @entry.unpublish!
    redirect_to changelog_entry_path(@entry), notice: "Changelog entry unpublished."
  end

  def link_feature_request
    fr = current_account.feature_requests.find(params[:feature_request_id])
    @entry.changelog_entry_feature_requests.find_or_create_by!(feature_request: fr)
    redirect_to changelog_entry_path(@entry), notice: "Feature request linked."
  end

  def unlink_feature_request
    fr = current_account.feature_requests.find(params[:feature_request_id])
    @entry.changelog_entry_feature_requests.find_by(feature_request: fr)&.destroy
    redirect_to changelog_entry_path(@entry), notice: "Feature request unlinked."
  end

  private

  def set_entry
    @entry = current_account.changelog_entries.find(params[:id])
  end

  def entry_params
    params.require(:changelog_entry).permit(:title, :body, :category, :version, :cover_image_url)
  end
end
