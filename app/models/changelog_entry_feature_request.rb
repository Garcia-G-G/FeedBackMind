class ChangelogEntryFeatureRequest < ApplicationRecord
  belongs_to :changelog_entry
  belongs_to :feature_request

  validates :feature_request_id, uniqueness: { scope: :changelog_entry_id }
end
