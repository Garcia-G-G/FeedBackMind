class AddApiTokenToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :api_token, :string
    add_index :accounts, :api_token, unique: true
  end
end
