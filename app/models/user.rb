class User < ApplicationRecord
  # === Devise ===
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable,
         :omniauthable, omniauth_providers: [:google_oauth2]
  include EmailDomainValidatable

  # === Associations ===
  belongs_to :account
  has_many :chat_messages, dependent: :destroy
  has_many :feature_requests, dependent: :nullify
  has_many :votes, dependent: :nullify

  # === Multi-tenancy ===
  acts_as_tenant(:account)

  # === Enums ===
  enum :role, { owner: 0, member: 1 }, prefix: true

  # === Validations ===
  validates :role, presence: true

  # === Scopes ===
  scope :owners, -> { where(role: :owner) }
  scope :members, -> { where(role: :member) }

  # === OmniAuth ===
  def self.from_omniauth(auth)
    # Try to find by provider + uid first
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    # Try to find by email (link existing account)
    email = auth.info.email.downcase
    user = find_by(email: email)
    if user
      user.update!(provider: auth.provider, uid: auth.uid)
      return user
    end

    # Create new account + user
    name = auth.info.name.presence || email.split("@").first.titleize
    subdomain = generate_subdomain(email)

    account = Account.create!(
      name: name,
      subdomain: subdomain,
      plan: :starter
    )

    create!(
      account: account,
      email: email,
      name: name,
      provider: auth.provider,
      uid: auth.uid,
      role: :owner,
      password: Devise.friendly_token(32)
    )
  end

  def self.generate_subdomain(email)
    base = email.split("@").first.parameterize
    base = "team-#{base}" if base.length < 3
    subdomain = base
    counter = 1
    while Account.exists?(subdomain: subdomain)
      subdomain = "#{base}-#{counter}"
      counter += 1
    end
    subdomain
  end

  # === Methods ===
  def owner?
    role_owner?
  end

  def display_name
    name.presence || email.split("@").first
  end
end
