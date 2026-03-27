class CreateChangelogEntryFeatureRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :changelog_entry_feature_requests do |t|
      t.references :changelog_entry, null: false, foreign_key: true
      t.references :feature_request, null: false, foreign_key: true

      t.timestamps
    end

    add_index :changelog_entry_feature_requests,
              [:changelog_entry_id, :feature_request_id],
              unique: true,
              name: "idx_changelog_feature_request_unique"
  end
end
