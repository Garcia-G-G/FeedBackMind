class CreateWeeklySyntheses < ActiveRecord::Migration[7.2]
  def change
    create_table :weekly_syntheses do |t|
      t.references :account, null: false, foreign_key: true
      t.date :week_start, null: false
      t.integer :feedback_count, default: 0
      t.jsonb :top_themes, default: []                # array of theme objects
      t.text :executive_summary
      t.jsonb :biggest_risk, default: {}              # { theme, potential_impact }
      t.string :quick_wins, array: true, default: []
      t.datetime :sent_at                             # when email digest was sent
      t.timestamps
    end

    add_index :weekly_syntheses, [:account_id, :week_start], unique: true
    add_index :weekly_syntheses, :week_start
  end
end
