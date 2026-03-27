class User < ApplicationRecord
  # === Devise ===
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable
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

  # === Methods ===
  def owner?
    role_owner?
  end

  def display_name
    name.presence || email.split("@").first
  end
end
