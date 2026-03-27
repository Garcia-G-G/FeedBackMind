class NpsResponse < ApplicationRecord
  # === Associations ===
  belongs_to :nps_survey, counter_cache: :responses_count
  belongs_to :account
  belongs_to :feedback, optional: true

  # === Multi-tenancy ===
  acts_as_tenant(:account)

  # === Validations ===
  validates :score, presence: true, inclusion: { in: 0..10 }

  # === Callbacks ===
  before_validation :set_category

  # === Scopes ===
  scope :promoters, -> { where(category: "promoter") }
  scope :passives, -> { where(category: "passive") }
  scope :detractors, -> { where(category: "detractor") }
  scope :with_comments, -> { where.not(comment: [nil, ""]) }
  scope :recent, -> { order(created_at: :desc) }

  private

  def set_category
    self.category = case score
                    when 9..10 then "promoter"
                    when 7..8 then "passive"
                    when 0..6 then "detractor"
                    end
  end
end
