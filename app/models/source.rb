class Source < ApplicationRecord
  # === Associations ===
  belongs_to :account
  has_many :feedbacks, dependent: :destroy

  # === Multi-tenancy ===
  acts_as_tenant(:account)

  # === Enums ===
  enum :source_type, {
    intercom: 0,
    gmail: 1,
    appstore: 2,
    playstore: 3,
    typeform: 4,
    jira: 5,
    slack: 6,
    csv: 7
  }, prefix: true

  # === Validations ===
  validates :source_type, presence: true
  validate :within_source_limit, on: :create

  # === Scopes ===
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_type, ->(type) { where(source_type: type) }
  scope :needs_sync, -> { active.where("last_synced_at IS NULL OR last_synced_at < ?", 1.hour.ago) }
  scope :app_store_sources, -> { where(source_type: [:appstore, :playstore]).active }

  # === Methods ===
  def mark_synced!
    update!(last_synced_at: Time.current)
  end

  def display_name
    "#{source_type.titleize} (#{account.name})"
  end

  # Config is stored as JSONB — access helpers
  def api_key
    config&.dig("api_key")
  end

  def webhook_url
    config&.dig("webhook_url")
  end

  private

  def within_source_limit
    return if account.nil?

    max = account.max_sources
    return if max == Float::INFINITY

    if account.sources.count >= max
      errors.add(:base, "Source limit reached for your plan (#{max}). Please upgrade.")
    end
  end
end
