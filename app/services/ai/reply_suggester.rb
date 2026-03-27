module Ai
  class ReplySuggester
    MODEL = "gpt-4.1-mini".freeze

    def self.suggest(feedback)
      new.suggest(feedback)
    end

    def suggest(feedback)
      client = OpenAI::Client.new

      response = client.chat(
        parameters: {
          model: MODEL,
          temperature: 0.4,
          max_tokens: 300,
          messages: [
            { role: "system", content: system_prompt(feedback.account) },
            { role: "user", content: user_prompt(feedback) }
          ]
        }
      )

      response.dig("choices", 0, "message", "content")
    rescue => e
      Rails.logger.error("[ReplySuggester] Failed for feedback ##{feedback.id}: #{e.message}")
      nil
    end

    private

    def system_prompt(account)
      <<~PROMPT
        You are a helpful customer success representative for #{account.name}. Generate a short, empathetic reply to customer feedback.

        Rules:
        - Be warm, professional, and concise (2-3 sentences max)
        - Acknowledge their specific concern
        - If it's a bug report, assure them it's being looked into
        - If it's a feature request, thank them and say you've noted it for the product team
        - If it's positive, thank them genuinely
        - Never promise specific timelines or features
        - Match the language of the feedback (if Spanish, reply in Spanish, etc.)
      PROMPT
    end

    def user_prompt(feedback)
      parts = ["Feedback from #{feedback.author_name || 'a customer'}:"]
      parts << feedback.content.truncate(1000)
      parts << "\nSentiment: #{feedback.sentiment}" if feedback.sentiment.present?
      parts.join("\n")
    end
  end
end
