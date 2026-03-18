class AppStoreScraperJob
  include Sidekiq::Job

  sidekiq_options queue: :low, retry: 2

  # Runs every 6 hours via sidekiq-cron.
  # Scrapes new reviews for accounts with active appstore/playstore sources.
  def perform
    Source.app_store_sources.includes(:account).find_each do |source|
      ActsAsTenant.with_tenant(source.account) do
        scrape_reviews(source)
      end
    rescue => e
      Rails.logger.error("[AppStoreScraperJob] Error scraping source #{source.id}: #{e.message}")
    end
  end

  private

  def scrape_reviews(source)
    # TODO: Implement App Store / Play Store review scraping
    # This would use the app_id from source.config to fetch new reviews
    # and enqueue each as a FeedbackIngestJob
    #
    # Example flow:
    # reviews = AppStoreClient.fetch_reviews(source.config["app_id"], since: source.last_synced_at)
    # reviews.each do |review|
    #   FeedbackIngestJob.perform_async(source.account_id, source.id, {
    #     external_id: review[:id],
    #     content: review[:text],
    #     author_name: review[:author],
    #     metadata: { rating: review[:rating], title: review[:title] },
    #     received_at: review[:date].iso8601
    #   })
    # end
    # source.mark_synced!
    Rails.logger.info("[AppStoreScraperJob] Scraping not yet implemented for source #{source.id}")
  end
end
