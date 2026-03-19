module Webhooks
  class GmailNormalizer
    def initialize(payload)
      @payload = payload
    end

    # Expects a normalized email payload (from Cloudflare Email Routing or Google Pub/Sub)
    # Format: { from, subject, body, message_id, date }
    def normalize
      return nil if @payload["body"].blank?

      {
        "external_id" => "gmail_#{@payload['message_id']}",
        "content" => "Subject: #{@payload['subject']}\n\n#{@payload['body']}",
        "author_email" => @payload["from"],
        "author_name" => extract_name(@payload["from"]),
        "metadata" => {
          "gmail_message_id" => @payload["message_id"],
          "subject" => @payload["subject"]
        },
        "received_at" => (@payload["date"] || Time.current).to_s
      }
    end

    private

    def extract_name(from)
      return nil unless from
      match = from.match(/^(.+?)\s*</)
      match ? match[1].strip : nil
    end
  end
end
