class CreateSources < ActiveRecord::Migration[7.2]
  def change
    create_table :sources do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :source_type, null: false              # enum: intercom=0, gmail=1, appstore=2, etc.
      t.jsonb :config, default: {}                     # encrypted credentials/tokens
      t.boolean :active, default: false, null: false
      t.datetime :last_synced_at
      t.timestamps
    end

    add_index :sources, [:account_id, :source_type]
    add_index :sources, [:account_id, :active]
  end
end
