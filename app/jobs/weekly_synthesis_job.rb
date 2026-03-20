class WeeklySynthesisJob
  include Sidekiq::Job

  sidekiq_options queue: :critical, retry: 2

  SYNTHESIS_MODEL = "gpt-4.1".freeze

  # Runs every Monday at 8am UTC via sidekiq-cron.
  # For each active account: collects last 7 days of feedback,
  # groups by semantic similarity, sends to GPT-4.1 for synthesis,
  # saves the WeeklySynthesis record, and sends the email digest.
  def perform
    week_start = Date.current.beginning_of_week(:monday)

    Account.active.find_each do |account|
      ActsAsTenant.with_tenant(account) do
        process_account(account, week_start)
      end
    rescue => e
      Rails.logger.error("[WeeklySynthesisJob] Error processing account #{account.id}: #{e.message}")
      Rails.logger.error(e.backtrace&.first(5)&.join("\n"))
      # Continue with next account, don't let one failure block all
    end
  end

  private

  def process_account(account, week_start)
    # Skip if synthesis already exists for this week
    return if WeeklySynthesis.exists?(account: account, week_start: week_start)

    feedbacks = account.feedbacks.processed.last_7_days
    return if feedbacks.empty?

    # Group feedbacks by semantic similarity for better synthesis
    clustered_text = build_clustered_context(feedbacks)

    # Call GPT-4.1 for synthesis
    client = OpenAI::Client.new
    response = client.chat(
      parameters: {
        model: SYNTHESIS_MODEL,
        response_format: { type: "json_object" },
        temperature: 0.3,
        max_tokens: 2000,
        messages: [
          { role: "system", content: synthesis_prompt(feedbacks.count, week_start, week_start + 6.days) },
          { role: "user", content: clustered_text }
        ]
      }
    )

    raw_json = response.dig("choices", 0, "message", "content")
    result = JSON.parse(raw_json)

    # Save the synthesis
    synthesis = WeeklySynthesis.create!(
      account: account,
      week_start: week_start,
      feedback_count: feedbacks.count,
      top_themes: result["top_themes"] || [],
      executive_summary: result["executive_summary"],
      biggest_risk: result["biggest_risk"] || {},
      quick_wins: result["quick_wins"] || []
    )

    # Send email digest to all account users
    WeeklyDigestMailer.digest_email(synthesis).deliver_later
    synthesis.mark_sent!

    Rails.logger.info("[WeeklySynthesisJob] Synthesis created for account #{account.id}, week #{week_start}")
  end

  def build_clustered_context(feedbacks)
    # Group feedbacks by topics for thematic clustering
    grouped = feedbacks.group_by { |f| f.topics&.first || "uncategorized" }

    grouped.map do |topic, items|
      section = "## Topic: #{topic} (#{items.count} feedbacks)\n\n"
      items.each do |f|
        section += "- [#{f.sentiment}] [#{f.source.source_type}] [#{f.received_at&.strftime('%Y-%m-%d')}]: #{f.content.truncate(500)}\n"
      end
      section
    end.join("\n\n")
  end

  def synthesis_prompt(feedback_count, week_start, week_end)
    File.read(Rails.root.join("app/prompts/weekly_synthesis.txt"))
        .gsub("{{feedback_count}}", feedback_count.to_s)
        .gsub("{{week_start}}", week_start.strftime("%B %d, %Y"))
        .gsub("{{week_end}}", week_end.strftime("%B %d, %Y"))
  end
end
