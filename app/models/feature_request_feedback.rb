class FeatureRequestFeedback < ApplicationRecord
  belongs_to :feature_request
  belongs_to :feedback

  validates :feedback_id, uniqueness: { scope: :feature_request_id }
end
