class CreateAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :subdomain, null: false
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.integer :plan, null: false, default: 0          # enum: starter=0, growth=1, scale=2
      t.integer :feedback_count_this_month, default: 0
      t.timestamps
    end

    add_index :accounts, :subdomain, unique: true
    add_index :accounts, :stripe_customer_id, unique: true, where: "stripe_customer_id IS NOT NULL"
    add_index :accounts, :plan
  end
end
