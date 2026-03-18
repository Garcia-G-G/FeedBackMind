class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      ## Devise fields
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip

      ## Custom fields
      t.references :account, null: false, foreign_key: true
      t.string :name
      t.integer :role, null: false, default: 0  # enum: owner=0, member=1

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, [:account_id, :role]
  end
end
