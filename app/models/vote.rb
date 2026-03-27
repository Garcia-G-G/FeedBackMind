class Vote < ApplicationRecord
  # === Associations ===
  belongs_to :feature_request, counter_cache: :votes_count
  belongs_to :account
  belongs_to :user, optional: true

  # === Multi-tenancy ===
  acts_as_tenant(:account)

  # === Validations ===
  validates :voter_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :voter_email, uniqueness: { scope: :feature_request_id, message: "has already voted on this request" }

  # === Callbacks ===
  before_validation :normalize_email

  private

  def normalize_email
    self.voter_email = voter_email&.strip&.downcase
  end
end
