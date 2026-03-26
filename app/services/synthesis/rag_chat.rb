module Synthesis
  class RagChat
    MODEL = "gpt-4.1".freeze
    MAX_CONTEXT_FEEDBACKS = 20

    def initialize(client: Openai::Client.new)
      @client = client
    end

    def ask(account:, question:)
      context = ""
      source_ids = []
      feedback_count = account.feedbacks.processed.count

      # Try semantic search if there are processed feedbacks
      if feedback_count > 0
        begin
          question_embedding = @client.embed(question)
          relevant_feedbacks = account.feedbacks
                                      .processed
                                      .with_embedding
                                      .nearest_to(question_embedding, limit: MAX_CONTEXT_FEEDBACKS)

          if relevant_feedbacks.any?
            context = relevant_feedbacks.map(&:to_context_string).join("\n\n---\n\n")
            source_ids = relevant_feedbacks.map(&:id)
          end
        rescue => e
          Rails.logger.warn("[RagChat] Embedding search failed: #{e.message}, proceeding without context")
        end
      end

      # Build user message with or without feedback context
      prompt = load_prompt(account.name)

      user_content = if context.present?
        "Relevant feedback context (#{source_ids.length} of #{feedback_count} total feedbacks):\n\n#{context}\n\n---\n\nQuestion: #{question}"
      else
        "Note: This workspace currently has #{feedback_count} feedbacks#{feedback_count == 0 ? ' (empty — no data yet)' : ' but none matched this query closely'}.\n\nQuestion: #{question}"
      end

      # Include recent chat history for conversational continuity
      recent_messages = account.chat_messages
                               .order(created_at: :desc)
                               .limit(6)
                               .reverse
                               .map { |m| { role: m.role, content: m.content } }

      messages = [{ role: "system", content: prompt }]
      messages += recent_messages if recent_messages.any?
      messages << { role: "user", content: user_content }

      answer = @client.chat(
        model: MODEL,
        temperature: 0.4,
        max_tokens: 1500,
        messages: messages
      )

      {
        answer: answer,
        source_feedback_ids: source_ids
      }
    end

    private

    def load_prompt(account_name)
      File.read(Rails.root.join("app/prompts/rag_chat.txt"))
          .gsub("{{account_name}}", account_name)
    end
  end
end
