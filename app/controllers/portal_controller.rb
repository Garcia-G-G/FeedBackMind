class PortalController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_tenant
  skip_before_action :check_onboarding

  layout "portal"

  before_action :find_account
  before_action :check_portal_enabled

  def show
    @voter_email = cookies.encrypted[:portal_voter_email]

    scope = @account.feature_requests.active

    scope = scope.search(params[:q]) if params[:q].present?
    scope = scope.by_status(params[:status]) if params[:status].present?
    scope = scope.by_category(params[:category]) if params[:category].present?

    @feature_requests = case params[:sort]
                        when "recent" then scope.by_recent
                        else scope.by_votes.by_recent
                        end

    @status_counts = @account.feature_requests.published.not_merged
                          .where.not(status: :declined)
                          .group(:status).count
    @categories = @account.feature_requests.active
                       .where.not(category: [nil, ""])
                       .distinct.pluck(:category).sort
  end

  def new_request
    @feature_request = FeatureRequest.new
    @voter_email = cookies.encrypted[:portal_voter_email]
  end

  def create_request
    @feature_request = @account.feature_requests.new(feature_request_params)
    @feature_request.published_at = Time.current

    if @feature_request.save
      # Auto-vote for own request
      @feature_request.votes.create(
        account: @account,
        voter_email: @feature_request.author_email.downcase,
        voter_name: @feature_request.author_name
      )

      cookies.encrypted[:portal_voter_email] = {
        value: @feature_request.author_email.downcase,
        expires: 1.year.from_now
      }

      redirect_to portal_path(portal_subdomain: @account.subdomain), notice: "Your feature request has been submitted!"
    else
      @voter_email = cookies.encrypted[:portal_voter_email]
      render :new_request, status: :unprocessable_entity
    end
  end

  def vote
    @feature_request = @account.feature_requests.active.find_by!(slug: params[:slug])
    email = params[:voter_email].presence || cookies.encrypted[:portal_voter_email]

    if email.blank?
      head :unprocessable_entity
      return
    end

    email = email.strip.downcase

    cookies.encrypted[:portal_voter_email] = {
      value: email,
      expires: 1.year.from_now
    }

    existing_vote = @feature_request.votes.find_by(voter_email: email)
    if existing_vote
      existing_vote.destroy
    else
      @feature_request.votes.create!(
        account: @account,
        voter_email: email,
        voter_name: params[:voter_name]
      )
    end

    @feature_request.reload
    @voter_email = email

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "vote-button-#{@feature_request.id}",
          partial: "portal/vote_button",
          locals: { feature_request: @feature_request, voter_email: @voter_email, account: @account }
        )
      end
      format.html { redirect_to portal_path(portal_subdomain: @account.subdomain) }
    end
  end

  def changelog
    scope = @account.changelog_entries.published
    scope = scope.by_category(params[:category]) if params[:category].present?
    @entries = scope.includes(:feature_requests)
  end

  def roadmap
    scope = @account.feature_requests.published.not_merged
    @planned = scope.where(status: :planned).by_votes
    @in_progress = scope.where(status: :in_progress).by_votes
    @shipped = scope.where(status: :shipped).by_votes.limit(10)
  end

  def show_request
    @feature_request = @account.feature_requests.active.find_by!(slug: params[:slug])
    @voter_email = cookies.encrypted[:portal_voter_email]
  end

  private

  def find_account
    @account = Account.find_by!(subdomain: params[:portal_subdomain])
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render plain: "Portal not found", status: :not_found
  end

  def check_portal_enabled
    unless @account.portal_enabled?
      render plain: "Feature request portal is not available on this plan.", status: :forbidden
    end
  end

  def feature_request_params
    params.require(:feature_request).permit(:title, :description, :category, :author_name, :author_email)
  end
end
