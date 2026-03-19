module Webhooks
  class TypeformNormalizer
    def initialize(payload)
      @payload = payload
    end

    def normalize
      form_response = @payload["form_response"]
      return nil unless form_response

      answers = form_response["answers"] || []
      content = answers.map { |a| extract_answer_text(a) }.compact.join("\n\n")
      return nil if content.blank?

      hidden = form_response.dig("hidden") || {}

      {
        "external_id" => "typeform_#{form_response['token']}",
        "content" => content,
        "author_email" => find_email(answers, hidden),
        "author_name" => hidden["name"],
        "metadata" => {
          "typeform_form_id" => @payload.dig("form_response", "form_id"),
          "typeform_response_id" => form_response["token"],
          "submitted_at" => form_response["submitted_at"]
        },
        "received_at" => form_response["submitted_at"] || Time.current.iso8601
      }
    end

    private

    def extract_answer_text(answer)
      case answer["type"]
      when "text", "long_text", "short_text", "email", "url"
        answer[answer["type"]]
      when "choice"
        answer.dig("choice", "label")
      when "choices"
        answer.dig("choices", "labels")&.join(", ")
      when "number", "rating", "opinion_scale"
        "Rating: #{answer[answer['type']]}"
      else
        nil
      end
    end

    def find_email(answers, hidden)
      email_answer = answers.find { |a| a["type"] == "email" }
      email_answer&.dig("email") || hidden["email"]
    end
  end
end
