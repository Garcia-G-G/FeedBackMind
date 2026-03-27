class BulkPriorityScoringJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 1

  def perform(account_id)
    account = Account.find(account_id)

    # Score unscored processed feedbacks
    account.feedbacks.processed.where(priority_score: nil).find_each do |feedback|
      FeedbackPriorityJob.perform_async(feedback.id)
      sleep(0.5) # Rate limiting
    end

    # Score feature requests
    account.feature_requests.not_merged.find_each do |fr|
      Ai::PriorityScorer.score_feature_request(fr)
    end

    Rails.logger.info("[BulkPriorityScoringJob] Completed for account #{account_id}")
  rescue => e
    Rails.logger.error("[BulkPriorityScoringJob] Failed for account #{account_id}: #{e.message}")
    raise
  end
end
