class FeedbackIngestJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 3

  # Receives a raw feedback hash from any source adapter, normalizes it
  # to the internal Feedback schema, deduplicates via external_id,
  # and enqueues FeedbackEmbedJob for AI processing.
  #
  # @param account_id [Integer]
  # @param source_id [Integer]
  # @param raw_data [Hash] with keys:
  #   - external_id (String, optional)
  #   - content (String, required)
  #   - author_email (String, optional)
  #   - author_name (String, optional)
  #   - metadata (Hash, optional)
  #   - received_at (String/ISO8601, optional)
  def perform(account_id, source_id, raw_data)
    account = Account.find(account_id)
    source = Source.find(source_id)

    # Enforce plan limits
    if account.feedback_limit_reached?
      Rails.logger.warn("[FeedbackIngestJob] Account #{account_id} hit feedback limit. Skipping.")
      # TODO: Trigger upgrade notification
      return
    end

    raw = raw_data.with_indifferent_access

    # Deduplicate by external_id
    if raw[:external_id].present?
      existing = Feedback.find_by(source_id: source_id, external_id: raw[:external_id])
      if existing
        Rails.logger.info("[FeedbackIngestJob] Duplicate feedback #{raw[:external_id]} for source #{source_id}. Skipping.")
        return
      end
    end

    feedback = Feedback.create!(
      account: account,
      source: source,
      external_id: raw[:external_id],
      content: raw[:content],
      author_email: raw[:author_email],
      author_name: raw[:author_name],
      metadata: raw[:metadata] || {},
      received_at: raw[:received_at] ? Time.parse(raw[:received_at]) : Time.current
    )

    Rails.logger.info("[FeedbackIngestJob] Created feedback ##{feedback.id} for account #{account_id}")
    # FeedbackEmbedJob is enqueued automatically via Feedback after_create_commit callback
  end
end
