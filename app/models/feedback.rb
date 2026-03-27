class Feedback < ApplicationRecord
  # === pgvector (neighbor gem) ===
  has_neighbors :embedding

  # === Associations ===
  belongs_to :account
  belongs_to :source
  belongs_to :company, optional: true, counter_cache: :feedback_count
  has_many :feature_request_feedbacks, dependent: :destroy
  has_many :feature_requests, through: :feature_request_feedbacks

  # === Multi-tenancy ===
  acts_as_tenant(:account)

  # === Enums ===
  enum :sentiment, { positive: 0, neutral: 1, negative: 2 }, prefix: true

  # === Validations ===
  validates :content, presence: true
  validates :external_id, uniqueness: { scope: :source_id }, allow_nil: true

  # === Scopes ===
  scope :unprocessed, -> { where(processed_at: nil) }
  scope :processed, -> { where.not(processed_at: nil) }
  scope :with_embedding, -> { where.not(embedding: nil) }
  scope :without_embedding, -> { where(embedding: nil) }
  scope :recent, -> { order(received_at: :desc) }
  scope :this_week, -> { where(received_at: 1.week.ago.beginning_of_day..Time.current) }
  scope :last_7_days, -> { where("received_at >= ?", 7.days.ago.beginning_of_day) }
  scope :by_sentiment, ->(sentiment) { where(sentiment: sentiment) }
  scope :by_topic, ->(topic) { where("? = ANY(topics)", topic) }
  scope :from_source_type, ->(type) { joins(:source).where(sources: { source_type: type }) }
  scope :by_tag, ->(tag) { where("? = ANY(tags)", tag) }
  scope :with_priority, -> { where.not(priority_score: nil) }
  scope :by_priority, -> { order(priority_score: :desc) }
  scope :critical_priority, -> { where(priority_label: "critical") }
  scope :high_priority, -> { where(priority_label: "high") }

  # === Callbacks ===
  after_create :increment_account_feedback_count
  after_create_commit :enqueue_embedding_job

  # === Semantic Search (using neighbor gem) ===
  # Find the N most similar feedbacks to a given embedding vector
  # Uses cosine distance via HNSW index for fast approximate nearest neighbor search
  scope :nearest_to, ->(embedding_vector, limit: 20) {
    nearest_neighbors(:embedding, embedding_vector, distance: "cosine").limit(limit)
  }

  # === Methods ===
  def processed?
    processed_at.present?
  end

  def has_embedding?
    embedding.present?
  end

  def priority_color_class
    case priority_label
    when "critical" then "bg-red-100 text-red-700"
    when "high" then "bg-amber-100 text-amber-700"
    when "medium" then "bg-blue-100 text-blue-700"
    when "low" then "bg-stone-100 text-stone-500"
    end
  end

  def priority_emoji
    case priority_label
    when "critical" then "🔴"
    when "high" then "🟠"
    when "medium" then "🔵"
    when "low" then "⚪"
    end
  end

  def mark_processed!
    update!(processed_at: Time.current)
  end

  # For display: formatted metadata
  def source_label
    "#{source&.source_type&.titleize || 'Unknown'} — #{received_at&.strftime('%b %d, %Y')}"
  end

  def to_context_string
    parts = []
    parts << "[Source: #{source.source_type}]"
    parts << "[Date: #{received_at&.strftime('%Y-%m-%d')}]"
    parts << "[Author: #{author_name || author_email || 'Anonymous'}]"
    parts << "[Sentiment: #{sentiment}]"
    parts << "[Company: #{company.name}]" if company.present?
    parts << content
    parts.join(" ")
  end

  private

  def increment_account_feedback_count
    account.increment_feedback_count!
  end

  def enqueue_embedding_job
    FeedbackEmbedJob.perform_async(id)
  end
end
