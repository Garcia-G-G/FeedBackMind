module Ai
  class PriorityScorer
    SCORING_MODEL = "gpt-4.1-mini".freeze

    def self.score_feedback(feedback)
      new.score_feedback(feedback)
    end

    def self.score_feature_request(feature_request)
      new.score_feature_request(feature_request)
    end

    def score_feedback(feedback)
      client = OpenAI::Client.new

      response = client.chat(
        parameters: {
          model: SCORING_MODEL,
          response_format: { type: "json_object" },
          temperature: 0.1,
          max_tokens: 300,
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: feedback.content.truncate(4000) }
          ]
        }
      )

      raw = response.dig("choices", 0, "message", "content")
      result = JSON.parse(raw)

      total = result["total_score"].to_i.clamp(0, 100)
      label = score_to_label(total)

      feedback.update!(
        priority_score: total,
        priority_label: label,
        priority_reasoning: result["reasoning"].to_s.truncate(500)
      )

      Rails.logger.info("[PriorityScorer] Scored feedback ##{feedback.id}: #{total} (#{label})")
    end

    def score_feature_request(feature_request)
      # Vote count normalized (0-40 points)
      max_votes = feature_request.account.feature_requests.maximum(:votes_count) || 1
      max_votes = [max_votes, 1].max
      vote_score = ((feature_request.votes_count.to_f / max_votes) * 40).round

      # Average priority_score of linked feedbacks (0-40 points)
      linked_scores = feature_request.feedbacks.where.not(priority_score: nil).pluck(:priority_score)
      avg_feedback_score = linked_scores.any? ? (linked_scores.sum.to_f / linked_scores.size) : 0
      feedback_score = ((avg_feedback_score / 100.0) * 40).round

      # Recency bonus (0-20 points)
      days_old = (Time.current - feature_request.created_at) / 1.day
      recency_score = if days_old < 7 then 20
                      elsif days_old < 30 then 15
                      elsif days_old < 90 then 10
                      else 5
                      end

      total = (vote_score + feedback_score + recency_score).clamp(0, 100)
      label = score_to_label(total)

      feature_request.update!(
        priority_score: total,
        priority_label: label
      )

      Rails.logger.info("[PriorityScorer] Scored feature_request ##{feature_request.id}: #{total} (#{label})")
    end

    private

    def score_to_label(score)
      case score
      when 76..100 then "critical"
      when 51..75 then "high"
      when 26..50 then "medium"
      else "low"
      end
    end

    def system_prompt
      <<~PROMPT
        You are a feedback priority scorer for a SaaS product. Evaluate the feedback on 4 dimensions, each scored 0-25:

        1. **Urgency** (0-25): How time-sensitive? Bugs, crashes, data loss = high. Nice-to-haves = low.
        2. **Business Impact** (0-25): Churn/revenue risk? Mentions of cancelling, switching, paying customers = high.
        3. **Frequency Signal** (0-25): Suggests many are affected? "Many users", "our team", "everyone" = high. Single personal issue = low.
        4. **Sentiment Severity** (0-25): How frustrated? Angry, blocking, desperate = high. Mild suggestion = low.

        Return ONLY valid JSON:
        {
          "urgency": <0-25>,
          "business_impact": <0-25>,
          "frequency_signal": <0-25>,
          "sentiment_severity": <0-25>,
          "total_score": <0-100>,
          "label": "critical" | "high" | "medium" | "low",
          "reasoning": "<one sentence explaining the score>"
        }

        Labels: critical=76-100, high=51-75, medium=26-50, low=0-25.
      PROMPT
    end
  end
end
