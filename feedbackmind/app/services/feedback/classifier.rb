module Feedback
  class Classifier
    MODEL = "gpt-4.1-mini".freeze

    def initialize(client: Openai::Client.new)
      @client = client
    end

    # Classify a single feedback's sentiment and generate topic tags
    # Returns { sentiment: String, topics: Array<String> }
    def classify(text)
      @client.chat_json(
        model: MODEL,
        temperature: 0.1,
        max_tokens: 200,
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: text.truncate(4000) }
        ]
      )
    end

    private

    def system_prompt
      <<~PROMPT
        You are a feedback classifier for a SaaS product. Analyze the user feedback and return ONLY valid JSON:

        {
          "sentiment": "positive" | "neutral" | "negative",
          "topics": ["topic1", "topic2", "topic3"]
        }

        Rules:
        - sentiment: classify the overall tone of the feedback
        - topics: 1-5 short lowercase tags (e.g., "onboarding", "billing", "performance", "ui", "mobile", "pricing", "support", "bugs", "feature-request")
        - Return ONLY the JSON object, nothing else
      PROMPT
    end
  end
end
