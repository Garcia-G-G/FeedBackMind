class ChangelogEntry < ApplicationRecord
  # === Associations ===
  belongs_to :account
  belongs_to :user, optional: true
  has_many :changelog_entry_feature_requests, dependent: :destroy
  has_many :feature_requests, through: :changelog_entry_feature_requests

  # === Multi-tenancy ===
  acts_as_tenant(:account)

  # === Enums ===
  enum :category, {
    new_feature: 0,
    improvement: 1,
    fix: 2,
    announcement: 3
  }, prefix: true

  # === Validations ===
  validates :title, presence: true, length: { maximum: 200 }
  validates :body, presence: true
  validates :slug, presence: true, uniqueness: { scope: :account_id }

  # === Callbacks ===
  before_validation :generate_slug, on: :create

  # === Scopes ===
  scope :published, -> { where.not(published_at: nil).order(published_at: :desc) }
  scope :draft, -> { where(published_at: nil) }
  scope :by_category, ->(cat) { where(category: cat) }

  # === Methods ===
  def published?
    published_at.present?
  end

  def publish!
    transaction do
      update!(published_at: Time.current)
      feature_requests.where.not(status: :shipped).find_each do |fr|
        fr.update!(status: :shipped)
      end
    end
  end

  def unpublish!
    update!(published_at: nil)
  end

  def category_emoji
    case category
    when "new_feature" then "🚀"
    when "improvement" then "✨"
    when "fix" then "🐛"
    when "announcement" then "📢"
    end
  end

  def category_color_class
    case category
    when "new_feature" then "bg-emerald-100 text-emerald-700"
    when "improvement" then "bg-blue-100 text-blue-700"
    when "fix" then "bg-amber-100 text-amber-700"
    when "announcement" then "bg-purple-100 text-purple-700"
    end
  end

  def category_label
    case category
    when "new_feature" then "New Feature"
    when "improvement" then "Improvement"
    when "fix" then "Fix"
    when "announcement" then "Announcement"
    end
  end

  def formatted_date
    (published_at || created_at).strftime("%B %d, %Y")
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
end
