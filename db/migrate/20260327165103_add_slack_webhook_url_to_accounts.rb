class AddSlackWebhookUrlToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :slack_webhook_url, :string
  end
end
