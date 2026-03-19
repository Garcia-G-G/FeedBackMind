module Webhooks
  class SlackNormalizer
    def initialize(payload)
      @payload = payload
    end

    def normalize
      event = @payload["event"]
      return nil unless event
      return nil unless event["type"] == "message"
      return nil if event["subtype"].present? # Skip bot messages, edits, etc.

      {
        "external_id" => "slack_#{event['channel']}_#{event['ts']}",
        "content" => event["text"],
        "author_name" => event["user"], # Slack user ID — could resolve via API later
        "metadata" => {
          "slack_channel" => event["channel"],
          "slack_ts" => event["ts"],
          "slack_thread_ts" => event["thread_ts"]
        },
        "received_at" => Time.at(event["ts"].to_f).iso8601
      }
    end
  end
end
