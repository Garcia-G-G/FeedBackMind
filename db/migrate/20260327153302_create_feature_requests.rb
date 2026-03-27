class CreateFeatureRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :feature_requests do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.references :merged_into, null: true, foreign_key: { to_table: :feature_requests }

      t.string :title, null: false
      t.text :description
      t.integer :status, default: 0, null: false
      t.string :category
      t.string :author_name
      t.string :author_email
      t.integer :votes_count, default: 0, null: false
      t.string :slug, null: false
      t.text :admin_notes
      t.datetime :shipped_at
      t.datetime :published_at

      t.timestamps
    end

    add_index :feature_requests, [:account_id, :slug], unique: true
    add_index :feature_requests, [:account_id, :status]
    add_index :feature_requests, [:account_id, :votes_count]
    add_index :feature_requests, [:account_id, :category]
    add_index :feature_requests, :author_email
  end
end
