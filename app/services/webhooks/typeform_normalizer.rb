module Webhooks
  class TypeformNormalizer
    def initialize(payload)
      @payload = payload
    end

    def normalize
      form_response = @payload["form_response"]
      return nil unless form_response

      answers = form_response["answers"] || []
      # Combine all text/long-text answers into one feedback string
      text_answers = answers.select { |a| %w[text long_text].include?(a["type"]) }
      content = text_answers.map { |a| a[a["type"]] }.join("\n\n")

      return nil if content.blank?

      hidden = form_response.dig("hidden") || {}

      {
        external_id: form_response["token"],
        content: content,
        author_email: extract_email(answers) || hidden["email"],
        author_name: hidden["name"],
        metadata: {
          form_id: form_response.dig("form_id"),
          score: extract_score(answers)
        }.compact,
        received_at: form_response["submitted_at"]
      }
    end

    private

    def extract_email(answers)
      email_answer = answers.find { |a| a["type"] == "email" }
      email_answer&.dig("email")
    end

    def extract_score(answers)
      score_answer = answers.find { |a| %w[number opinion_scale rating].include?(a["type"]) }
      score_answer&.dig("number") || score_answer&.dig("number")
    end
  end
end
