class DashboardController < ApplicationController
  def index
    @period = params[:period] || "7"
    date_range = calculate_date_range(@period)

    feedbacks_in_period = current_account.feedbacks.where(received_at: date_range)

    @feedbacks_count = feedbacks_in_period.count
    @active_sources_count = current_account.sources.where(active: true).count
    @total_sources_count = current_account.sources.count
    @unprocessed_count = current_account.feedbacks.unprocessed.count

    # Sentiment
    processed = feedbacks_in_period.where.not(sentiment: nil)
    positive_count = processed.where(sentiment: :positive).count
    neutral_count = processed.where(sentiment: :neutral).count
    negative_count = processed.where(sentiment: :negative).count
    total_processed = positive_count + neutral_count + negative_count

    @sentiment_score = total_processed > 0 ? ((positive_count.to_f / total_processed) * 100).round : 0
    @sentiment_data = { positive: positive_count, neutral: neutral_count, negative: negative_count }

    # Timeline
    @sentiment_timeline = compute_sentiment_timeline(date_range)

    # Recent feedbacks
    @recent_feedbacks = current_account.feedbacks.includes(:source).order(received_at: :desc).limit(10)

    # Weekly synthesis + themes
    @weekly_synthesis = current_account.weekly_syntheses.order(week_start: :desc).first
    @themes = @weekly_synthesis&.themes || []

    # Priority queue
    @priority_feedbacks = current_account.feedbacks.with_priority
                               .where(priority_label: %w[critical high])
                               .by_priority.includes(:source).limit(5)

    # Onboarding checklist
    if current_user.checklist_dismissed_at.nil?
      @checklist = current_account.onboarding_checklist
      @checklist_progress = current_account.checklist_progress
    end

    # Sources for grid
    @sources = current_account.sources.order(:source_type)

    # Feature requests
    if current_account.portal_enabled?
      fr_scope = current_account.feature_requests.not_merged
      @fr_counts = fr_scope.group(:status).count
      @top_request = fr_scope.published.by_votes.first
    end
  end

  private

  def calculate_date_range(period)
    days = case period.to_i
           when 7 then 7
           when 30 then 30
           when 90 then 90
           else 7
           end
    days.days.ago..Time.current
  end

  def compute_sentiment_timeline(date_range)
    start_date = date_range.first.to_date
    end_date = date_range.last.to_date

    (start_date..end_date).map do |date|
      day_feedbacks = current_account.feedbacks.where(received_at: date.beginning_of_day..date.end_of_day).where.not(sentiment: nil)
      {
        date: date,
        label: date.strftime("%a"),
        positive: day_feedbacks.where(sentiment: :positive).count,
        neutral: day_feedbacks.where(sentiment: :neutral).count,
        negative: day_feedbacks.where(sentiment: :negative).count
      }
    end
  end
end
