module Synthesis
  class WeeklyBuilder
    MODEL = "gpt-4.1".freeze

    def initialize(client: Openai::Client.new)
      @client = client
    end

    # Build a weekly synthesis for an account's recent feedback
    # Returns parsed JSON hash matching the WeeklySynthesis schema
    def build(feedbacks:, week_start:, week_end:)
      clustered_text = cluster_feedbacks(feedbacks)
      prompt = load_prompt(feedbacks.count, week_start, week_end)

      @client.chat_json(
        model: MODEL,
        temperature: 0.3,
        max_tokens: 2000,
        messages: [
          { role: "system", content: prompt },
          { role: "user", content: clustered_text }
        ]
      )
    end

    private

    def cluster_feedbacks(feedbacks)
      grouped = feedbacks.group_by { |f| f.topics&.first || "uncategorized" }

      grouped.map do |topic, items|
        section = "## Topic: #{topic} (#{items.count} feedbacks)\n\n"
        items.each do |f|
          section += "- [#{f.sentiment}] [#{f.source.source_type}] [#{f.received_at&.strftime('%Y-%m-%d')}]: #{f.content.truncate(500)}\n"
        end
        section
      end.join("\n\n")
    end

    def load_prompt(count, week_start, week_end)
      template = File.read(Rails.root.join("app/prompts/weekly_synthesis.txt"))
      template
        .gsub("{{feedback_count}}", count.to_s)
        .gsub("{{week_start}}", week_start.strftime("%B %d, %Y"))
        .gsub("{{week_end}}", week_end.strftime("%B %d, %Y"))
    end
  end
end
