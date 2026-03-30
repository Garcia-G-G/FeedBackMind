class Invitation < ApplicationRecord
  belongs_to :account
  belongs_to :invited_by, class_name: "User"

  enum :role, { member: 0, admin: 1 }, prefix: true

  validates :email, presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            uniqueness: { scope: :account_id, message: "has already been invited" }
  validates :token, presence: true, uniqueness: true
  validate :cannot_invite_existing_member

  before_validation :generate_token_and_expiry, on: :create
  before_validation :normalize_email

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where(accepted_at: nil).where("expires_at <= ?", Time.current) }
  scope :accepted, -> { where.not(accepted_at: nil) }

  def expired?
    expires_at <= Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def pending?
    !accepted? && !expired?
  end

  def accept!(user)
    update!(accepted_at: Time.current)
  end

  private

  def generate_token_and_expiry
    self.token ||= SecureRandom.urlsafe_base64(32)
    self.expires_at ||= 7.days.from_now
  end

  def normalize_email
    self.email = email&.strip&.downcase
  end

  def cannot_invite_existing_member
    return if email.blank? || account.nil?
    if account.users.exists?(email: email)
      errors.add(:email, "is already a team member")
    end
  end
end
