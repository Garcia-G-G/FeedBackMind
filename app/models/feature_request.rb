class FeatureRequest < ApplicationRecord
  # === Associations ===
  belongs_to :account
  belongs_to :user, optional: true
  belongs_to :merged_into, class_name: "FeatureRequest", optional: true
  has_many :merged_requests, class_name: "FeatureRequest", foreign_key: :merged_into_id, dependent: :nullify
  has_many :votes, dependent: :destroy
  has_many :feature_request_feedbacks, dependent: :destroy
  has_many :feedbacks, through: :feature_request_feedbacks

  # === Multi-tenancy ===
  acts_as_tenant(:account)

  # === Enums ===
  enum :status, {
    open: 0,
    planned: 1,
    in_progress: 2,
    shipped: 3,
    declined: 4
  }, prefix: true

  # === Validations ===
  validates :title, presence: true, length: { maximum: 200 }
  validates :description, length: { maximum: 5000 }
  validates :author_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :slug, presence: true, uniqueness: { scope: :account_id }

  # === Callbacks ===
  before_validation :generate_slug, on: :create
  before_save :set_shipped_at

  # === Scopes ===
  scope :published, -> { where.not(published_at: nil) }
  scope :draft, -> { where(published_at: nil) }
  scope :not_merged, -> { where(merged_into_id: nil) }
  scope :active, -> { published.not_merged.where.not(status: :declined) }
  scope :by_votes, -> { order(votes_count: :desc) }
  scope :by_recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_category, ->(category) { where(category: category) }
  scope :search, ->(query) {
    where("title ILIKE :q OR description ILIKE :q", q: "%#{sanitize_sql_like(query)}%")
  }

  # === Methods ===
  def published?
    published_at.present?
  end

  def merged?
    merged_into_id.present?
  end

  def publish!
    update!(published_at: Time.current)
  end

  def unpublish!
    update!(published_at: nil)
  end

  def merge_into!(target)
    transaction do
      votes.each do |vote|
        unless target.votes.exists?(voter_email: vote.voter_email)
          vote.update!(feature_request: target)
        end
      end
      target.update_column(:votes_count, target.votes.count)
      update_column(:votes_count, votes.count)

      feature_request_feedbacks.each do |frf|
        unless target.feature_request_feedbacks.exists?(feedback_id: frf.feedback_id)
          frf.update!(feature_request: target)
        end
      end

      update!(merged_into: target)
    end
  end

  def voted_by?(email)
    votes.exists?(voter_email: email.downcase)
  end

  def status_color_class
    case status
    when "open" then "bg-blue-100 text-blue-700"
    when "planned" then "bg-purple-100 text-purple-700"
    when "in_progress" then "bg-amber-100 text-amber-700"
    when "shipped" then "bg-emerald-100 text-emerald-700"
    when "declined" then "bg-stone-100 text-stone-500"
    end
  end

  private

  def generate_slug
    return if slug.present?
    base = title.to_s.parameterize.first(60)
    candidate = base
    counter = 1
    while self.class.where(account: account).exists?(slug: candidate)
      candidate = "#{base}-#{counter}"
      counter += 1
    end
    self.slug = candidate
  end

  def set_shipped_at
    if status_changed? && status_shipped?
      self.shipped_at = Time.current
    elsif status_changed? && !status_shipped?
      self.shipped_at = nil
    end
  end
end
