class SourceSyncJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 3

  def perform(source_id)
    source = Source.find(source_id)
    return unless source.active?

    syncer = case source.source_type.to_sym
             when :slack then Sources::SlackSync.new(source)
             when :gmail then Sources::GmailSync.new(source)
             when :jira then Sources::JiraSync.new(source)
             when :typeform then Sources::TypeformSync.new(source)
             else
               Rails.logger.warn("[SourceSync] No sync service for #{source.source_type}")
               return
             end

    syncer.sync
    source.mark_synced!
  rescue => e
    Rails.logger.error("[SourceSync] Failed for source #{source_id}: #{e.message}")
    raise
  end
end
