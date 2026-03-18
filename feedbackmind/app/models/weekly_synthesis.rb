class WeeklySynthesis < ApplicationRecord
  # === Associations ===
  belongs_to :account

  # === Multi-tenancy ===
  acts_as_tenant(:account)

  # === Validations ===
  validates :week_start, presence: true
  validates :week_start, uniqueness: { scope: :account_id }

  # === Scopes ===
  scope :recent, -> { order(week_start: :desc) }
  scope :sent, -> { where.not(sent_at: nil) }
  scope :unsent, -> { where(sent_at: nil) }
  scope :for_week, ->(date) { where(week_start: date.beginning_of_week(:monday)) }

  # === Methods ===
  def sent?
    sent_at.present?
  end

  def mark_sent!
    update!(sent_at: Time.current)
  end

  def week_end
    week_start + 6.days
  end

  def week_label
    "#{week_start.strftime('%b %d')} — #{week_end.strftime('%b %d, %Y')}"
  end

  # Access top_themes as an array of OpenStruct for easier template rendering
  def themes
    (top_themes || []).map { |t| OpenStruct.new(t) }
  end

  def risk
    OpenStruct.new(biggest_risk) if biggest_risk.present?
  end
end
