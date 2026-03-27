class NpsSurvey < ApplicationRecord
  # === Associations ===
  belongs_to :account
  has_many :nps_responses, dependent: :destroy

  # === Multi-tenancy ===
  acts_as_tenant(:account)

  # === Validations ===
  validates :name, presence: true
  validates :question, presence: true
  validates :survey_token, presence: true, uniqueness: true

  # === Callbacks ===
  before_validation :generate_survey_token, on: :create

  # === Scopes ===
  scope :active, -> { where(active: true) }

  # === Methods ===
  def nps_score
    breakdown = nps_breakdown
    return 0 if breakdown[:total].zero?
    promoter_pct = (breakdown[:promoters].to_f / breakdown[:total] * 100)
    detractor_pct = (breakdown[:detractors].to_f / breakdown[:total] * 100)
    (promoter_pct - detractor_pct).round
  end

  def nps_breakdown
    responses = nps_responses
    {
      promoters: responses.promoters.count,
      passives: responses.passives.count,
      detractors: responses.detractors.count,
      total: responses.count
    }
  end

  def nps_trend(days: 30)
    start_date = days.days.ago.to_date
    end_date = Date.current

    (start_date..end_date).map do |date|
      day_responses = nps_responses.where(created_at: date.beginning_of_day..date.end_of_day)
      count = day_responses.count
      if count > 0
        promoters = day_responses.promoters.count
        detractors = day_responses.detractors.count
        score = (((promoters.to_f / count) - (detractors.to_f / count)) * 100).round
      else
        score = nil
      end
      { date: date, score: score, count: count }
    end
  end

  def embed_snippet
    host = ENV.fetch("APP_HOST", "5.161.238.195.sslip.io")
    protocol = ENV.fetch("APP_PROTOCOL", "https")
    %(<script src="#{protocol}://#{host}/nps/widget.js" data-token="#{survey_token}" data-color="#{brand_color}" data-position="#{position}" async></script>)
  end

  private

  def generate_survey_token
    return if survey_token.present?
    loop do
      self.survey_token = "nps_#{SecureRandom.hex(16)}"
      break unless self.class.exists?(survey_token: survey_token)
    end
  end
end
