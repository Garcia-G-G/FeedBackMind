# PROMPT 14 — Fix Controllers + Views to Use Real Data

The dashboard and views currently have hardcoded fallback data. Fix them to use ONLY real data from the database. Also fix bugs found in audit.

## Task 1: Fix ApplicationController

The new ApplicationController must:
- Keep `before_action :authenticate_user!` but SKIP it for PagesController#home
- Set tenant properly: `ActsAsTenant.current_tenant = current_user.account`
- Add `helper_method :current_account`
- NOT break existing API controllers (they inherit from Api::V1::BaseController which has its own auth)

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :authenticate_user!, unless: :devise_controller?
  before_action :set_tenant, if: :user_signed_in?

  helper_method :current_account

  private

  def current_account
    ActsAsTenant.current_tenant
  end

  def set_tenant
    ActsAsTenant.current_tenant = current_user.account
  end
end
```

## Task 2: Fix PagesController
The PagesController#home should NOT require authentication. Add:
```ruby
class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
  end
end
```

## Task 3: Fix DashboardController to compute ALL real data

The dashboard controller must compute everything the view needs with zero hardcoded values:

```ruby
class DashboardController < ApplicationController
  def index
    @period = (params[:period] || "7").to_i
    @date_range = @period.days.ago..Time.current

    feedbacks = current_account.feedbacks.where(created_at: @date_range)

    # Metrics
    @feedbacks_count = feedbacks.count
    @total_feedbacks = current_account.feedbacks.count

    processed = feedbacks.where.not(sentiment: nil)
    positive_count = processed.where(sentiment: :positive).count
    neutral_count = processed.where(sentiment: :neutral).count
    negative_count = processed.where(sentiment: :negative).count
    total_processed = processed.count

    @sentiment_score = total_processed > 0 ? ((positive_count.to_f / total_processed) * 100).round : 0
    @sentiment_data = { positive: positive_count, neutral: neutral_count, negative: negative_count }

    @active_sources_count = current_account.sources.where(active: true).count
    @total_sources_count = current_account.sources.count

    # Recent feedbacks
    @recent_feedbacks = current_account.feedbacks
      .includes(:source)
      .order(created_at: :desc)
      .limit(10)

    # Weekly synthesis (latest)
    @weekly_synthesis = current_account.weekly_syntheses.order(week_start: :desc).first

    # Themes from synthesis
    @themes = @weekly_synthesis&.themes || []

    # Sources
    @sources = current_account.sources.order(:source_type)

    # Sentiment timeline (daily counts for the period)
    @sentiment_timeline = compute_sentiment_timeline(feedbacks)

    # Pipeline counts
    @unprocessed_count = current_account.feedbacks.unprocessed.count
    @processed_count = current_account.feedbacks.where.not(sentiment: nil).count
  end

  private

  def compute_sentiment_timeline(feedbacks)
    days = (@period || 7).to_i
    (0...days).map do |i|
      date = i.days.ago.to_date
      day_feedbacks = feedbacks.where(created_at: date.beginning_of_day..date.end_of_day)
      {
        date: date,
        label: date.strftime("%a"),
        positive: day_feedbacks.where(sentiment: :positive).count,
        neutral: day_feedbacks.where(sentiment: :neutral).count,
        negative: day_feedbacks.where(sentiment: :negative).count
      }
    end.reverse
  end
end
```

## Task 4: Fix dashboard view to use ONLY real data

Update `app/views/dashboard/index.html.erb`:
- Replace ALL hardcoded numbers with instance variables
- The sentiment timeline should iterate `@sentiment_timeline` instead of hardcoded Mon-Sun
- The themes section should iterate `@themes` array from the synthesis
- The recent feedbacks should iterate `@recent_feedbacks`
- The sources grid should iterate `@sources`
- Add proper empty states when data is nil/empty
- Keep the same Tailwind design but make it data-driven

For the sentiment timeline bars, calculate proportional heights:
```erb
<%% max_count = @sentiment_timeline.map { |d| d[:positive] + d[:neutral] + d[:negative] }.max || 1 %>
<%% @sentiment_timeline.each do |day| %>
  <%% total = day[:positive] + day[:neutral] + day[:negative] %>
  <%% pos_height = total > 0 ? (day[:positive].to_f / max_count * 90).round : 0 %>
  <%% neg_height = total > 0 ? (day[:negative].to_f / max_count * 90).round : 0 %>
  <%% neu_height = total > 0 ? (day[:neutral].to_f / max_count * 90).round : 0 %>
  <!-- bar group with dynamic heights -->
<%% end %>
```

## Task 5: Fix ChatController — Add plan gate

The chat controller is missing the plan check. Fix it:
```ruby
class ChatController < ApplicationController
  def create
    unless current_account.chat_enabled?
      redirect_to dashboard_path, alert: "AI Chat is available on Growth and Scale plans."
      return
    end
    # ... rest of implementation
  end
end
```

## Task 6: Fix FeedbacksController — Real filtering

Make sure the feedbacks index actually filters using params:
```ruby
def index
  @feedbacks = current_account.feedbacks.includes(:source).order(created_at: :desc)
  @feedbacks = @feedbacks.where(sentiment: params[:sentiment]) if params[:sentiment].present?
  @feedbacks = @feedbacks.joins(:source).where(sources: { source_type: params[:source_type] }) if params[:source_type].present?
  @feedbacks = @feedbacks.where("content ILIKE ?", "%#{params[:search]}%") if params[:search].present?

  # Simple pagination
  @page = (params[:page] || 1).to_i
  @per_page = 20
  @total_count = @feedbacks.count
  @feedbacks = @feedbacks.offset((@page - 1) * @per_page).limit(@per_page)
end
```

## Task 7: Fix feedbacks view filters to submit as GET params

The filter form in feedbacks/index should use `form_with url: feedbacks_path, method: :get, data: { turbo_frame: "_top" }` so filters work with Turbo and browser back button.

## Task 8: Verify all pages load
After fixes, start the server and visit every route:
- /dashboard
- /feedbacks
- /feedbacks/1
- /syntheses
- /sources
- /pipeline
- /loop_tracker
- /settings

Every page should render with REAL data from seeds. No page should crash.
