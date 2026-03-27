class CreateChangelogEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :changelog_entries do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true

      t.string :title, null: false
      t.text :body, null: false
      t.integer :category, default: 0, null: false
      t.string :slug, null: false
      t.string :version
      t.datetime :published_at
      t.string :cover_image_url

      t.timestamps
    end

    add_index :changelog_entries, [:account_id, :slug], unique: true
    add_index :changelog_entries, [:account_id, :published_at]
    add_index :changelog_entries, [:account_id, :category]
  end
end
