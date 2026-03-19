class DashboardController < ApplicationController
  def index
    @feedbacks_count = current_account.feedbacks.count
    @active_sources_count = current_account.sources.where(active: true).count
    @total_sources_count = current_account.sources.count

    @recent_feedbacks = current_account.feedbacks
      .order(created_at: :desc)
      .limit(10)

    @weekly_themes = current_account.weekly_syntheses
      .order(week_start: :desc)
      .first

    @period = params[:period] || "7"
    date_range = calculate_date_range(@period)

    feedbacks_in_period = current_account.feedbacks
      .where(created_at: date_range)

    positive_count = feedbacks_in_period.where(sentiment: :positive).count
    neutral_count = feedbacks_in_period.where(sentiment: :neutral).count
    negative_count = feedbacks_in_period.where(sentiment: :negative).count

    total_count = positive_count + neutral_count + negative_count
    positive_percentage = total_count > 0 ? ((positive_count.to_f / total_count) * 100).round(1) : 0

    @sentiment_score = positive_percentage
    @sentiment_data = {
      positive: positive_count,
      neutral: neutral_count,
      negative: negative_count
    }
  end

  private

  def calculate_date_range(period)
    case period.to_i
    when 7
      7.days.ago..Time.current
    when 30
      30.days.ago..Time.current
    when 90
      90.days.ago..Time.current
    else
      7.days.ago..Time.current
    end
  end
end
