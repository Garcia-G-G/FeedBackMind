class SavedView < ApplicationRecord
  belongs_to :account
  belongs_to :user

  acts_as_tenant(:account)

  validates :name, presence: true
  validates :filters, presence: true

  scope :ordered, -> { order(position: :asc, created_at: :asc) }

  # Built-in views that are always available
  PRESETS = [
    { name: "High Priority", icon: "🔴", filters: { sort: "priority", status: "processed" } },
    { name: "New This Week", icon: "🆕", filters: { status: "processed", period: "7" } },
    { name: "Unprocessed", icon: "⏳", filters: { status: "unprocessed" } },
    { name: "Negative", icon: "😞", filters: { sentiment: "negative" } }
  ].freeze

  def to_query_params
    filters.to_query
  end
end
