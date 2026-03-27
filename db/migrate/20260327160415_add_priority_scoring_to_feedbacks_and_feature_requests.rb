class AddPriorityScoringToFeedbacksAndFeatureRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :feedbacks, :priority_score, :integer
    add_column :feedbacks, :priority_label, :string
    add_column :feedbacks, :priority_reasoning, :text

    add_column :feature_requests, :priority_score, :integer
    add_column :feature_requests, :priority_label, :string

    add_index :feedbacks, [:account_id, :priority_score]
    add_index :feature_requests, [:account_id, :priority_score]
  end
end
