# Scheduled jobs via sidekiq-cron
Sidekiq.configure_server do |config|
  config.on(:startup) do
    schedule = {
      "weekly_synthesis" => {
        "cron" => "0 8 * * 1",                          # Every Monday at 8:00 AM UTC
        "class" => "WeeklySynthesisJob",
        "queue" => "critical",
        "description" => "Generate weekly feedback synthesis for all active accounts"
      },
      "app_store_scraper" => {
        "cron" => "0 */6 * * *",                         # Every 6 hours
        "class" => "AppStoreScraperJob",
        "queue" => "low",
        "description" => "Scrape new App Store and Play Store reviews"
      },
      "monthly_feedback_reset" => {
        "cron" => "0 0 1 * *",                           # 1st of each month at midnight UTC
        "class" => "MonthlyFeedbackCountResetJob",
        "queue" => "critical",
        "description" => "Reset monthly feedback counters for all accounts"
      }
    }

    Sidekiq::Cron::Job.load_from_hash!(schedule)
  end
end
