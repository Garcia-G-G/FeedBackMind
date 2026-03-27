module Notifications
  class SlackNotifier
    def initialize(account)
      @account = account
      @webhook_url = account.slack_webhook_url
    end

    def notify(text:, blocks: nil)
      return unless @webhook_url.present?

      payload = { text: text }
      payload[:blocks] = blocks if blocks.present?

      uri = URI(@webhook_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/json"
      req.body = payload.to_json

      response = http.request(req)
      Rails.logger.info("[SlackNotifier] Sent to #{@account.name}: #{response.code}")
    rescue => e
      Rails.logger.error("[SlackNotifier] Failed for #{@account.name}: #{e.message}")
    end

    def new_feedback(feedback)
      notify(
        text: "New feedback from #{feedback.author_name || feedback.author_email || 'Anonymous'}: #{feedback.content.truncate(200)}",
        blocks: [
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "*New Feedback* from #{feedback.source&.source_type&.titleize || 'Unknown'}\n\n#{feedback.content.truncate(300)}"
            }
          },
          {
            type: "context",
            elements: [
              { type: "mrkdwn", text: "Author: #{feedback.author_name || feedback.author_email || 'Anonymous'}" },
              { type: "mrkdwn", text: "Source: #{feedback.source&.source_type&.titleize}" }
            ]
          }
        ]
      )
    end

    def synthesis_ready(synthesis)
      themes_text = synthesis.themes.first(3).map { |t|
        title = t.respond_to?(:title) ? t.title : t["title"]
        "• #{title}"
      }.join("\n")

      notify(
        text: "Weekly synthesis ready for #{synthesis.week_label}",
        blocks: [
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "*Weekly Synthesis Ready* — #{synthesis.week_label}\n\n#{themes_text}"
            }
          }
        ]
      )
    end

    def high_priority_feedback(feedback)
      return unless feedback.priority_score.present? && feedback.priority_score >= 76

      notify(
        text: "🔴 Critical priority feedback (score: #{feedback.priority_score}): #{feedback.content.truncate(200)}",
        blocks: [
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "*🔴 Critical Priority Feedback* (Score: #{feedback.priority_score}/100)\n\n#{feedback.content.truncate(300)}\n\n_#{feedback.priority_reasoning}_"
            }
          }
        ]
      )
    end
  end
end
