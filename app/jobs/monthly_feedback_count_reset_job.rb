class MonthlyFeedbackCountResetJob
  include Sidekiq::Job

  sidekiq_options queue: :critical, retry: 1

  # Runs on the 1st of each month via sidekiq-cron.
  # Resets feedback_count_this_month to 0 for all accounts.
  def perform
    count = Account.update_all(feedback_count_this_month: 0)
    Rails.logger.info("[MonthlyFeedbackCountResetJob] Reset feedback count for #{count} accounts")
  end
end
