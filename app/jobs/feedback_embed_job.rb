class FeedbackEmbedJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 3

  EMBEDDING_MODEL = "text-embedding-3-small".freeze
  CLASSIFICATION_MODEL = "gpt-4.1-mini".freeze

  # Takes a Feedback record, generates its vector embedding using OpenAI,
  # classifies sentiment and generates topic tags, then marks it as processed.
  #
  # @param feedback_id [Integer]
  def perform(feedback_id)
    feedback = Feedback.find_by(id: feedback_id)
    return unless feedback
    return if feedback.processed?

    client = OpenAI::Client.new

    # Step 1: Generate embedding vector via text-embedding-3-small
    embedding_response = client.embeddings(
      parameters: {
        model: EMBEDDING_MODEL,
        input: feedback.content.truncate(8000) # Safety limit
      }
    )

    embedding_vector = embedding_response.dig("data", 0, "embedding")

    unless embedding_vector
      Rails.logger.error("[FeedbackEmbedJob] No embedding returned for feedback ##{feedback_id}")
      raise "Embedding generation failed for feedback ##{feedback_id}"
    end

    # Step 2: Classify sentiment + generate topic tags via gpt-4.1-mini
    classification_response = client.chat(
      parameters: {
        model: CLASSIFICATION_MODEL,
        response_format: { type: "json_object" },
        temperature: 0.1,
        max_tokens: 200,
        messages: [
          {
            role: "system",
            content: <<~PROMPT
              You are a feedback classifier for a SaaS product. Analyze the user feedback below and return ONLY valid JSON:

              {
                "sentiment": "positive" | "neutral" | "negative",
                "topics": ["topic1", "topic2", "topic3"]
              }

              Rules:
              - sentiment: classify the overall tone
              - topics: 1-5 short lowercase tags describing what the feedback is about (e.g., "onboarding", "billing", "performance", "ui", "mobile", "pricing", "support")
              - Return ONLY the JSON, no explanations
            PROMPT
          },
          {
            role: "user",
            content: feedback.content.truncate(4000)
          }
        ]
      }
    )

    raw_json = classification_response.dig("choices", 0, "message", "content")
    classification = JSON.parse(raw_json)

    # Step 3: Update the feedback record with all AI-generated data
    feedback.update!(
      embedding: embedding_vector,
      sentiment: classification["sentiment"],
      topics: Array(classification["topics"]).map(&:downcase).uniq.first(5),
      processed_at: Time.current
    )

    Rails.logger.info("[FeedbackEmbedJob] Processed feedback ##{feedback_id}: sentiment=#{classification['sentiment']}, topics=#{classification['topics']}")

    # Enqueue priority scoring
    FeedbackPriorityJob.perform_async(feedback_id)

  rescue JSON::ParserError => e
    Rails.logger.error("[FeedbackEmbedJob] JSON parse error for feedback ##{feedback_id}: #{e.message}")
    raise # Retry via Sidekiq
  rescue Faraday::Error => e
    Rails.logger.error("[FeedbackEmbedJob] OpenAI API error for feedback ##{feedback_id}: #{e.message}")
    raise # Retry via Sidekiq
  end
end
