module Sources
  class SlackSync
    LIMIT = 50

    def initialize(source)
      @source = source
      @token = source.config["access_token"]
      @account = source.account
    end

    def sync
      return if @token.blank?

      channels = fetch_channels
      channels.each do |channel|
        messages = fetch_messages(channel["id"])
        messages.each do |msg|
          next if msg["subtype"].present?
          next if msg["bot_id"].present?

          raw_data = {
            "external_id" => "slack_#{channel['id']}_#{msg['ts']}",
            "content" => msg["text"],
            "author_name" => msg["user"] || "Unknown",
            "metadata" => { "channel" => channel["name"], "ts" => msg["ts"], "thread_ts" => msg["thread_ts"] },
            "received_at" => Time.at(msg["ts"].to_f).iso8601
          }

          FeedbackIngestJob.perform_async(@account.id, @source.id, raw_data)
        end
      end
    end

    private

    def fetch_channels
      uri = URI("https://slack.com/api/conversations.list")
      uri.query = URI.encode_www_form(token: @token, types: "public_channel,private_channel", limit: 20)
      response = Net::HTTP.get(uri)
      data = JSON.parse(response)
      data["ok"] ? data["channels"].select { |c| c["is_member"] } : []
    rescue => e
      Rails.logger.error("[SlackSync] Failed to fetch channels: #{e.message}")
      []
    end

    def fetch_messages(channel_id)
      uri = URI("https://slack.com/api/conversations.history")
      uri.query = URI.encode_www_form(token: @token, channel: channel_id, limit: LIMIT)
      response = Net::HTTP.get(uri)
      data = JSON.parse(response)
      data["ok"] ? data["messages"] : []
    rescue => e
      Rails.logger.error("[SlackSync] Failed to fetch messages for #{channel_id}: #{e.message}")
      []
    end
  end
end
