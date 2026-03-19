module Webhooks
  class IntercomNormalizer
    def initialize(payload)
      @payload = payload
    end

    def normalize
      return nil unless relevant_event?

      data = @payload.dig("data", "item") || {}
      conversation_parts = data.dig("conversation_parts", "conversation_parts") || []

      content = extract_content(data, conversation_parts)
      return nil if content.blank?

      user = data.dig("user") || data.dig("contacts", "contacts", 0) || {}

      {
        "external_id" => data["id"]&.to_s,
        "content" => content,
        "author_email" => user["email"],
        "author_name" => user["name"],
        "metadata" => {
          "intercom_conversation_id" => data["id"],
          "tags" => extract_tags(data),
          "url" => data["url"]
        },
        "received_at" => Time.at(data["created_at"].to_i).iso8601
      }
    end

    private

    def relevant_event?
      topic = @payload["topic"]
      %w[
        conversation.user.created
        conversation.user.replied
        conversation/user/created
        conversation/user/replied
      ].include?(topic)
    end

    def extract_content(data, parts)
      body = data.dig("source", "body")
      return ActionController::Base.helpers.strip_tags(body) if body.present?

      user_part = parts.find { |p| p["part_type"] == "comment" && p.dig("author", "type") == "user" }
      user_part ? ActionController::Base.helpers.strip_tags(user_part["body"]) : nil
    end

    def extract_tags(data)
      (data.dig("tags", "tags") || []).map { |t| t["name"] }
    end
  end
end
