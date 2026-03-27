class Company < ApplicationRecord
  # === Associations ===
  belongs_to :account
  has_many :feedbacks, dependent: :nullify

  # === Multi-tenancy ===
  acts_as_tenant(:account)

  # === Constants ===
  SEGMENTS = ["Enterprise", "Mid-Market", "SMB", "Startup", "Free Trial", "Churned"].freeze

  # === Validations ===
  validates :name, presence: true
  validates :domain, uniqueness: { scope: :account_id }, allow_nil: true

  # === Scopes ===
  scope :by_feedback_count, -> { order(feedback_count: :desc) }
  scope :by_mrr, -> { order(Arel.sql("mrr DESC NULLS LAST")) }
  scope :by_segment, ->(segment) { where(segment: segment) }
  scope :with_domain, -> { where.not(domain: nil) }
  scope :search, ->(query) {
    where("name ILIKE :q OR domain ILIKE :q", q: "%#{sanitize_sql_like(query)}%")
  }

  # === Methods ===
  def feedback_sentiment_breakdown
    feedbacks.where.not(sentiment: nil).group(:sentiment).count
  end

  def average_priority_score
    feedbacks.with_priority.average(:priority_score)&.round
  end

  def recent_feedbacks(limit = 10)
    feedbacks.includes(:source).order(received_at: :desc).limit(limit)
  end

  def sentiment_trend_last_30_days
    start_date = 30.days.ago.to_date
    (start_date..Date.current).map do |date|
      day_fb = feedbacks.where(received_at: date.beginning_of_day..date.end_of_day).where.not(sentiment: nil)
      {
        date: date,
        positive: day_fb.where(sentiment: :positive).count,
        neutral: day_fb.where(sentiment: :neutral).count,
        negative: day_fb.where(sentiment: :negative).count
      }
    end
  end

  def top_topics(limit = 10)
    feedbacks.where.not(topics: nil).pluck(:topics).flatten.tally.sort_by { |_, v| -v }.first(limit)
  end

  def segment_color_class
    case segment
    when "Enterprise" then "bg-purple-100 text-purple-700"
    when "Mid-Market" then "bg-blue-100 text-blue-700"
    when "SMB" then "bg-emerald-100 text-emerald-700"
    when "Startup" then "bg-amber-100 text-amber-700"
    when "Free Trial" then "bg-stone-100 text-stone-600"
    when "Churned" then "bg-red-100 text-red-700"
    else "bg-stone-100 text-stone-500"
    end
  end
end
