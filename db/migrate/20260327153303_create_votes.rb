class CreateVotes < ActiveRecord::Migration[7.2]
  def change
    create_table :votes do |t|
      t.references :feature_request, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true

      t.string :voter_email, null: false
      t.string :voter_name

      t.timestamps
    end

    add_index :votes, [:feature_request_id, :voter_email], unique: true, name: "idx_votes_unique_per_email"
    add_index :votes, [:account_id, :voter_email]
  end
end
