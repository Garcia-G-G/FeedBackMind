module Openai
  class Client
    attr_reader :client

    def initialize
      @client = OpenAI::Client.new
    end

    # Generate embedding for a text string using text-embedding-3-small
    # Returns an array of 1536 floats
    def embed(text, model: "text-embedding-3-small")
      response = client.embeddings(
        parameters: {
          model: model,
          input: text.truncate(8000)
        }
      )
      response.dig("data", 0, "embedding")
    end

    # Chat completion with JSON response format
    def chat_json(messages:, model: "gpt-4.1", temperature: 0.3, max_tokens: 2000)
      response = client.chat(
        parameters: {
          model: model,
          response_format: { type: "json_object" },
          temperature: temperature,
          max_tokens: max_tokens,
          messages: messages
        }
      )
      raw = response.dig("choices", 0, "message", "content")
      JSON.parse(raw)
    end

    # Chat completion with plain text response
    def chat(messages:, model: "gpt-4.1", temperature: 0.5, max_tokens: 1500)
      response = client.chat(
        parameters: {
          model: model,
          temperature: temperature,
          max_tokens: max_tokens,
          messages: messages
        }
      )
      response.dig("choices", 0, "message", "content")
    end
  end
end
