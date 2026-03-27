class FeedbackPriorityJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 2

  def perform(feedback_id)
    feedback = Feedback.find_by(id: feedback_id)
    return unless feedback
    return if feedback.priority_score.present?

    Ai::PriorityScorer.score_feedback(feedback)

    feedback.reload
    Notifications::SlackNotifier.new(feedback.account).high_priority_feedback(feedback)
  rescue => e
    Rails.logger.error("[FeedbackPriorityJob] Failed for feedback #{feedback_id}: #{e.message}")
    raise
  end
end
