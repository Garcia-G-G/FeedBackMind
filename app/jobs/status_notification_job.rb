class StatusNotificationJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 2

  def perform(feature_request_id)
    feature_request = FeatureRequest.find_by(id: feature_request_id)
    return unless feature_request
    return unless feature_request.published?

    voter_emails = feature_request.votes.pluck(:voter_email).uniq

    voter_emails.each do |email|
      FeatureRequestMailer.status_update(feature_request, email).deliver_later
    rescue => e
      Rails.logger.error("[StatusNotificationJob] Failed to send to #{email}: #{e.message}")
    end

    Rails.logger.info("[StatusNotificationJob] Sent #{voter_emails.size} notifications for feature_request ##{feature_request_id}")
  end
end
