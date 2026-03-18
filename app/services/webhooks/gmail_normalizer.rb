module Webhooks
  class GmailNormalizer
    def initialize(payload)
      @payload = payload
    end

    def normalize
      body = @payload["body"] || @payload["text"] || @payload["snippet"]
      return nil if body.blank?

      {
        external_id: @payload["message_id"] || @payload["id"],
        content: body,
        author_email: @payload["from"] || @payload["sender"],
        author_name: extract_name(@payload["from"]),
        metadata: {
          subject: @payload["subject"],
          thread_id: @payload["thread_id"]
        }.compact,
        received_at: @payload["date"] || @payload["received_at"]
      }
    end

    private

    def extract_name(from)
      return nil unless from
      # "John Doe <john@example.com>" → "John Doe"
      match = from.match(/\A(.+?)\s*</)
      match ? match[1].strip : nil
    end
  end
end
