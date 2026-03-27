class CreateCompanies < ActiveRecord::Migration[7.2]
  def change
    create_table :companies do |t|
      t.references :account, null: false, foreign_key: true

      t.string :name, null: false
      t.string :domain
      t.string :segment
      t.integer :plan_tier
      t.decimal :mrr, precision: 10, scale: 2
      t.integer :feedback_count, default: 0, null: false
      t.text :notes
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :companies, [:account_id, :domain], unique: true, where: "domain IS NOT NULL"
    add_index :companies, [:account_id, :segment]
    add_index :companies, [:account_id, :feedback_count]
    add_index :companies, [:account_id, :mrr]

    add_reference :feedbacks, :company, null: true, foreign_key: true
    add_index :feedbacks, [:company_id, :received_at]
  end
end
