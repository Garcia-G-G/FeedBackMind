module Sources
  class GmailSync
    LIMIT = 50

    def initialize(source)
      @source = source
      @token = source.config["access_token"]
      @account = source.account
    end

    def sync
      return if @token.blank?

      message_ids = fetch_message_ids
      message_ids.each do |msg_id|
        email = fetch_message(msg_id)
        next unless email

        headers = email.dig("payload", "headers") || []
        subject = headers.find { |h| h["name"] == "Subject" }&.dig("value") || ""
        from = headers.find { |h| h["name"] == "From" }&.dig("value") || ""
        date = headers.find { |h| h["name"] == "Date" }&.dig("value")

        body = extract_body(email["payload"])
        next if body.blank?

        author_name = from.match(/^(.+?)\s*</)&.captures&.first || from.split("@").first
        author_email = from.match(/<(.+?)>/)&.captures&.first || from

        received_at = begin
          date.present? ? Time.parse(date).iso8601 : Time.current.iso8601
        rescue
          Time.current.iso8601
        end

        raw_data = {
          "external_id" => "gmail_#{msg_id}",
          "content" => "#{subject}: #{body}".truncate(2000),
          "author_name" => author_name,
          "author_email" => author_email,
          "metadata" => { "subject" => subject, "message_id" => msg_id },
          "received_at" => received_at
        }

        FeedbackIngestJob.perform_async(@account.id, @source.id, raw_data)
      end
    end

    private

    def fetch_message_ids
      uri = URI("https://gmail.googleapis.com/gmail/v1/users/me/messages")
      uri.query = URI.encode_www_form(maxResults: LIMIT, q: "is:inbox")
      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer #{@token}"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.request(req)
      data = JSON.parse(response.body)
      (data["messages"] || []).map { |m| m["id"] }
    rescue => e
      Rails.logger.error("[GmailSync] Failed to fetch message IDs: #{e.message}")
      []
    end

    def fetch_message(msg_id)
      uri = URI("https://gmail.googleapis.com/gmail/v1/users/me/messages/#{msg_id}")
      uri.query = URI.encode_www_form(format: "full")
      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer #{@token}"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.request(req)
      JSON.parse(response.body)
    rescue => e
      Rails.logger.error("[GmailSync] Failed to fetch message #{msg_id}: #{e.message}")
      nil
    end

    def extract_body(payload)
      if payload["body"] && payload["body"]["data"]
        Base64.urlsafe_decode64(payload["body"]["data"]).force_encoding("UTF-8")
      elsif payload["parts"]
        text_part = payload["parts"].find { |p| p["mimeType"] == "text/plain" }
        if text_part && text_part.dig("body", "data")
          Base64.urlsafe_decode64(text_part["body"]["data"]).force_encoding("UTF-8")
        else
          ""
        end
      else
        ""
      end.truncate(2000)
    rescue
      ""
    end
  end
end
