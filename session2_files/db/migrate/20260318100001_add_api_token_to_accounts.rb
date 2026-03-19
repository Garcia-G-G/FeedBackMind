class AddApiTokenToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :api_token, :string
    add_index :accounts, :api_token, unique: true

    reversible do |dir|
      dir.up do
        Account.find_each do |account|
          account.update_column(:api_token, SecureRandom.hex(32))
        end
      end
    end
  end
end
