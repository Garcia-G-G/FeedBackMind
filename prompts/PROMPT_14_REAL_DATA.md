# PROMPT 14 — Make Dashboard + Views Use REAL Data Only

The dashboard and views have hardcoded fallback data. Replace ALL hardcoded values with real database queries. Fix bugs found in audit.

## Task 1: Fix DashboardController

Rewrite the index action to compute ALL metrics from real data:
- @period from params (default "7")
- @feedbacks_count from feedbacks in date range
- @sentiment_score calculated from processed feedbacks (positive / total * 100)
- @sentiment_data hash { positive: count, neutral: count, negative: count }
- @active_sources_count and @total_sources_count from sources
- @recent_feedbacks (last 10, includes :source)
- @weekly_synthesis (latest WeeklySynthesis)
- @themes from synthesis.themes parsed as array of hashes
- @sentiment_timeline — compute daily sentiment counts for each day in the period
- @sources for the sources grid
- @unprocessed_count for pipeline

Add a private method compute_sentiment_timeline that returns array of { date:, label:, positive:, neutral:, negative: } for each day.

## Task 2: Update dashboard view (app/views/dashboard/index.html.erb)

Replace ALL hardcoded numbers with ERB variables:
- "1,284" → number_with_delimiter(@feedbacks_count)
- "72%" → @sentiment_score
- "6 / 8" → @active_sources_count / @total_sources_count
- Sentiment timeline: iterate @sentiment_timeline with proportional bar heights
- Themes: iterate @themes (handle nil/empty with empty state)
- Recent feedbacks: iterate @recent_feedbacks
- Sources grid: iterate @sources with source_emoji helper
- Sentiment donut: calculate stroke-dasharray from @sentiment_data

Show proper empty states when data is nil/empty (centered icon + "No data yet" message).

## Task 3: Fix ChatController — Add plan gate

Add `current_account.chat_enabled?` check. If not enabled, respond with turbo_stream error message or redirect with alert.

## Task 4: Fix FeedbacksController — Real filtering

The index must filter using params:
- params[:sentiment] → where(sentiment: value)
- params[:source_type] → joins(:source).where(sources: { source_type: value })
- params[:search] → where("content ILIKE ?", "%#{value}%")
- Paginate with page/per_page (default 20)

## Task 5: Fix feedbacks/index.html.erb filters

The filter form must use `form_with url: feedbacks_path, method: :get` with select dropdowns that preserve current filter values. Add "Clear filters" link.

## Task 6: Fix all other controllers to use real data

- SynthesesController: query real syntheses, themes from JSONB
- SourcesController: real sources with feedback counts
- PipelineController: real unprocessed vs processed feedbacks grouped by topic
- LoopTrackerController: real data grouping resolved feedbacks
- SettingsController: real account data, plan info

## Task 7: Verify every page loads with real seed data

Start the server and visit every route. Every page should render with data from seeds, NO hardcoded fallbacks, NO crashes.
