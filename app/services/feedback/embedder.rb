module Feedback
  class Embedder
    def initialize(client: Openai::Client.new)
      @client = client
    end

    # Generate embedding vector for a feedback's content
    # Returns Array<Float> of 1536 dimensions
    def embed(text)
      @client.embed(text)
    end
  end
end
