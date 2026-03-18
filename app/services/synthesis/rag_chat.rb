module Synthesis
  class RagChat
    MODEL = "gpt-4.1".freeze
    MAX_CONTEXT_FEEDBACKS = 20

    def initialize(client: Openai::Client.new)
      @client = client
    end

    # Answer a PM's question using RAG over the feedback history
    # Returns { answer: String, source_feedback_ids: Array<Integer> }
    def ask(account:, question:)
      # Step 1: Embed the question
      question_embedding = @client.embed(question)

      # Step 2: Find most relevant feedbacks via semantic search (HNSW cosine)
      relevant_feedbacks = account.feedbacks
                                  .processed
                                  .with_embedding
                                  .nearest_to(question_embedding, limit: MAX_CONTEXT_FEEDBACKS)

      # Step 3: Build context string from relevant feedbacks
      context = relevant_feedbacks.map(&:to_context_string).join("\n\n---\n\n")

      # Step 4: Generate answer with GPT-4.1
      prompt = load_prompt(account.name)
      answer = @client.chat(
        model: MODEL,
        temperature: 0.4,
        max_tokens: 1500,
        messages: [
          { role: "system", content: prompt },
          { role: "user", content: "Relevant feedback context:\n\n#{context}\n\n---\n\nQuestion: #{question}" }
        ]
      )

      {
        answer: answer,
        source_feedback_ids: relevant_feedbacks.map(&:id)
      }
    end

    private

    def load_prompt(account_name)
      File.read(Rails.root.join("app/prompts/rag_chat.txt"))
          .gsub("{{account_name}}", account_name)
    end
  end
end
