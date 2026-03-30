class AddConfirmableToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string

    add_index :users, :confirmation_token, unique: true

    # Mark all existing users as confirmed so they don't get locked out
    reversible do |dir|
      dir.up do
        User.update_all(confirmed_at: Time.current)
      end
    end
  end
end
