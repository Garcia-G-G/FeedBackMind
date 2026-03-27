class CompaniesController < ApplicationController
  before_action :set_company, only: [:show, :edit, :update, :destroy]

  def index
    scope = current_account.companies

    scope = scope.search(params[:q]) if params[:q].present?
    scope = scope.by_segment(params[:segment]) if params[:segment].present?

    @companies = case params[:sort]
                 when "mrr" then scope.by_mrr
                 when "name" then scope.order(:name)
                 when "recent" then scope.order(created_at: :desc)
                 else scope.by_feedback_count
                 end

    @total_count = current_account.companies.count
    @total_feedback = current_account.companies.sum(:feedback_count)
    @segment_counts = current_account.companies.where.not(segment: nil).group(:segment).count
  end

  def show
    @sentiment_breakdown = @company.feedback_sentiment_breakdown
    @recent_feedbacks = @company.recent_feedbacks(15)
    @top_topics = @company.top_topics(10)
  end

  def edit
  end

  def update
    if @company.update(company_params)
      redirect_to company_path(@company), notice: "Company updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @company.destroy
    redirect_to companies_path, notice: "Company deleted."
  end

  def auto_match
    matcher = Companies::AutoMatcher.new(current_account)
    matched = matcher.match_all
    redirect_to companies_path, notice: "Auto-match complete: #{matched} feedbacks matched to companies."
  end

  private

  def set_company
    @company = current_account.companies.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name, :domain, :segment, :mrr, :notes)
  end
end
