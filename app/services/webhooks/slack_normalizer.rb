module Webhooks
  class SlackNormalizer
    def initialize(payload)
      @payload = payload
      @event = payload["event"] || {}
    end

    def normalize
      text = @event["text"]
      return nil if text.blank?

      {
        external_id: @event["client_msg_id"] || @event["ts"],
        content: text,
        author_name: @event["user"],
        metadata: {
          channel: @event["channel"],
          team_id: @payload["team_id"],
          thread_ts: @event["thread_ts"]
        }.compact,
        received_at: parse_slack_ts(@event["ts"])
      }
    end

    private

    def parse_slack_ts(ts)
      return nil unless ts
      Time.at(ts.to_f).iso8601
    end
  end
end
