module Webhooks
  class JiraNormalizer
    def initialize(payload)
      @payload = payload
    end

    def normalize
      return nil unless relevant_event?

      issue = @payload["issue"] || {}
      fields = issue["fields"] || {}
      comment = @payload.dig("comment")

      content = if comment
                  comment["body"]
                else
                  [fields["summary"], fields["description"]].compact.join("\n\n")
                end

      return nil if content.blank?

      reporter = fields.dig("reporter") || {}

      {
        "external_id" => "jira_#{issue['key']}_#{comment&.dig('id') || 'issue'}",
        "content" => content,
        "author_email" => reporter["emailAddress"] || comment&.dig("author", "emailAddress"),
        "author_name" => reporter["displayName"] || comment&.dig("author", "displayName"),
        "metadata" => {
          "jira_key" => issue["key"],
          "jira_type" => fields.dig("issuetype", "name"),
          "jira_priority" => fields.dig("priority", "name"),
          "jira_status" => fields.dig("status", "name"),
          "jira_url" => issue["self"]
        },
        "received_at" => (fields["created"] || Time.current).to_s
      }
    end

    private

    def relevant_event?
      event = @payload["webhookEvent"]
      %w[jira:issue_created jira:issue_updated comment_created].include?(event)
    end
  end
end
