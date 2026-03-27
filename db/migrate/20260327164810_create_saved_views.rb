class CreateSavedViews < ActiveRecord::Migration[7.2]
  def change
    create_table :saved_views do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.string :name, null: false
      t.string :icon
      t.jsonb :filters, default: {}, null: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :saved_views, [:account_id, :user_id]
  end
end
