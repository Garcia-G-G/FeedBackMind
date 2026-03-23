class ChatMessage < ApplicationRecord
  # === Associations ===
  belongs_to :account
  belongs_to :user

  # === Multi-tenancy ===
  acts_as_tenant(:account)

  # === Enums ===
  enum :role, { user: 0, assistant: 1 }, prefix: true

  # === Validations ===
  validates :content, presence: true, length: { maximum: 10_000 }
  validates :role, presence: true

  # === Callbacks ===
  before_save :sanitize_content

  private

  def sanitize_content
    self.content = ActionController::Base.helpers.sanitize(content) if role_user?
  end

  public

  # === Scopes ===
  scope :recent, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :from_user_role, -> { where(role: :user) }
  scope :from_assistant, -> { where(role: :assistant) }

  # === Methods ===

  # Retrieve the Feedback records that were used as RAG context
  def source_feedbacks
    return Feedback.none if source_feedback_ids.blank?

    Feedback.where(id: source_feedback_ids)
  end

  def user_message?
    role_user?
  end

  def assistant_message?
    role_assistant?
  end
end
