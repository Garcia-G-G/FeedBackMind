module Webhooks
  class IntercomNormalizer
    def initialize(payload)
      @payload = payload
    end

    def normalize
      conversation = @payload.dig("data", "item")
      return nil unless conversation

      body = conversation.dig("conversation_message", "body") ||
             conversation.dig("conversation_parts", "conversation_parts", 0, "body")

      return nil if body.blank?

      {
        external_id: conversation["id"]&.to_s,
        content: strip_html(body),
        author_email: conversation.dig("conversation_message", "author", "email"),
        author_name: conversation.dig("conversation_message", "author", "name"),
        metadata: {
          topic: @payload["topic"],
          tags: conversation["tags"]&.dig("tags")&.map { |t| t["name"] }
        }.compact,
        received_at: parse_time(conversation["created_at"])
      }
    end

    private

    def strip_html(html)
      ActionView::Base.full_sanitizer.sanitize(html).squish
    end

    def parse_time(timestamp)
      return nil unless timestamp
      Time.at(timestamp).iso8601
    end
  end
end
