class CreateFeatureRequestFeedbacks < ActiveRecord::Migration[7.2]
  def change
    create_table :feature_request_feedbacks do |t|
      t.references :feature_request, null: false, foreign_key: true
      t.references :feedback, null: false, foreign_key: true

      t.timestamps
    end

    add_index :feature_request_feedbacks, [:feature_request_id, :feedback_id], unique: true, name: "idx_fr_feedback_unique"
  end
end
