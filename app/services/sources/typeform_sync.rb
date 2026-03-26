module Sources
  class TypeformSync
    LIMIT = 50

    def initialize(source)
      @source = source
      @token = source.config["access_token"]
      @account = source.account
    end

    def sync
      return if @token.blank?

      forms = fetch_forms
      forms.each do |form|
        responses = fetch_responses(form["id"])
        responses.each do |resp|
          answers_text = extract_answers(resp["answers"] || [])
          next if answers_text.blank?

          email = find_email(resp)

          raw_data = {
            "external_id" => "typeform_#{resp['response_id']}",
            "content" => answers_text.truncate(2000),
            "author_name" => email&.split("@")&.first || "Anonymous",
            "author_email" => email,
            "metadata" => {
              "form_id" => form["id"],
              "form_title" => form["title"],
              "response_id" => resp["response_id"],
              "submitted_at" => resp["submitted_at"]
            },
            "received_at" => resp["submitted_at"] || Time.current.iso8601
          }

          FeedbackIngestJob.perform_async(@account.id, @source.id, raw_data)
        end
      end
    end

    private

    def fetch_forms
      uri = URI("https://api.typeform.com/forms")
      uri.query = URI.encode_www_form(page_size: 10)
      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer #{@token}"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.request(req)
      data = JSON.parse(response.body)
      data["items"] || []
    rescue => e
      Rails.logger.error("[TypeformSync] Failed to fetch forms: #{e.message}")
      []
    end

    def fetch_responses(form_id)
      uri = URI("https://api.typeform.com/forms/#{form_id}/responses")
      uri.query = URI.encode_www_form(page_size: LIMIT)
      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer #{@token}"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.request(req)
      data = JSON.parse(response.body)
      data["items"] || []
    rescue => e
      Rails.logger.error("[TypeformSync] Failed to fetch responses for #{form_id}: #{e.message}")
      []
    end

    def extract_answers(answers)
      answers.filter_map do |a|
        case a["type"]
        when "text", "long_text", "short_text" then a.dig(a["type"], "value") || a["text"]
        when "email" then a.dig("email")
        when "choice" then a.dig("choice", "label")
        when "choices" then a.dig("choices", "labels")&.join(", ")
        when "number", "rating", "opinion_scale" then a.dig(a["type"], "value")&.to_s
        end
      end.join("\n")
    end

    def find_email(response)
      email_answer = (response["answers"] || []).find { |a| a["type"] == "email" }
      email_answer&.dig("email") || response.dig("hidden", "email")
    end
  end
end
