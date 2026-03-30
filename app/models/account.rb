class Account < ApplicationRecord
  # === Multi-tenancy ===
  has_many :users, dependent: :destroy
  has_many :sources, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  has_many :weekly_syntheses, dependent: :destroy
  has_many :chat_messages, dependent: :destroy
  has_many :feature_requests, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :changelog_entries, dependent: :destroy
  has_many :nps_surveys, dependent: :destroy
  has_many :nps_responses, dependent: :destroy
  has_many :companies, dependent: :destroy
  has_many :saved_views, dependent: :destroy
  has_many :invitations, dependent: :destroy

  # === Enums ===
  enum :plan, { starter: 0, growth: 1, scale: 2 }, prefix: true

  # === Callbacks ===
  before_create :generate_api_token

  # === Validations ===
  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9][a-z0-9\-]*[a-z0-9]\z/,
                       message: "must be lowercase alphanumeric with hyphens only" },
            length: { minimum: 3, maximum: 63 }

  validates :plan, presence: true
  validates :feedback_count_this_month, numericality: { greater_than_or_equal_to: 0 }

  # === Scopes ===
  scope :active, -> { joins(:sources).where(sources: { active: true }).distinct }
  scope :with_plan, ->(plan) { where(plan: plan) }
  scope :billable, -> { where.not(stripe_subscription_id: nil) }

  # === Plan Limits ===
  PLAN_LIMITS = {
    "starter" => { users: 1, sources: 3, feedbacks_per_month: 1_000, chat_enabled: false, prd_enabled: false, portal_enabled: false },
    "growth"  => { users: 5, sources: 10, feedbacks_per_month: 10_000, chat_enabled: true, prd_enabled: false, portal_enabled: true },
    "scale"   => { users: Float::INFINITY, sources: Float::INFINITY, feedbacks_per_month: Float::INFINITY, chat_enabled: true, prd_enabled: true, portal_enabled: true }
  }.freeze

  def plan_limits
    PLAN_LIMITS[plan]
  end

  def feedback_limit_reached?
    return false if plan_scale?

    feedback_count_this_month >= plan_limits[:feedbacks_per_month]
  end

  def chat_enabled?
    plan_limits[:chat_enabled]
  end

  def prd_enabled?
    plan_limits[:prd_enabled]
  end

  def portal_enabled?
    plan_limits[:portal_enabled]
  end

  def max_users
    plan_limits[:users]
  end

  def onboarding_checklist
    [
      { key: :connect_source, label: "Connect a feedback source", done: sources.active.any?, path: "sources/new" },
      { key: :first_feedback, label: "Receive your first feedback", done: feedbacks.any?, path: "feedbacks" },
      { key: :first_synthesis, label: "Generate an AI synthesis", done: weekly_syntheses.any?, path: "syntheses/new" },
      { key: :invite_member, label: "Invite a team member", done: users.count > 1, path: "settings" },
      { key: :create_nps, label: "Create an NPS survey", done: nps_surveys.any?, path: "nps/new" }
    ]
  end

  def checklist_progress
    items = onboarding_checklist
    completed = items.count { |i| i[:done] }
    { completed: completed, total: items.size, percentage: (completed.to_f / items.size * 100).round }
  end

  def max_sources
    plan_limits[:sources]
  end

  def increment_feedback_count!
    increment!(:feedback_count_this_month)
  end

  def reset_feedback_count!
    update!(feedback_count_this_month: 0)
  end

  def regenerate_api_token!
    update!(api_token: self.class.generate_unique_token)
  end

  def self.generate_unique_token
    loop do
      token = "fm_#{SecureRandom.hex(24)}"
      break token unless exists?(api_token: token)
    end
  end

  private

  def generate_api_token
    self.api_token ||= self.class.generate_unique_token
  end
end
