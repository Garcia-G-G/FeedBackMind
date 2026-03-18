module Webhooks
  class JiraNormalizer
    def initialize(payload)
      @payload = payload
    end

    def normalize
      comment = @payload["comment"]
      return nil unless comment

      body = comment.dig("body")
      return nil if body.blank?

      issue = @payload["issue"] || {}

      {
        external_id: comment["id"]&.to_s,
        content: body,
        author_email: comment.dig("author", "emailAddress"),
        author_name: comment.dig("author", "displayName"),
        metadata: {
          issue_key: issue["key"],
          issue_summary: issue.dig("fields", "summary"),
          issue_type: issue.dig("fields", "issuetype", "name"),
          project: issue.dig("fields", "project", "key")
        }.compact,
        received_at: comment["created"]
      }
    end
  end
end
