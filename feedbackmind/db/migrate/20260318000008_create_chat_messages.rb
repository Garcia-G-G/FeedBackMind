class CreateChatMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :chat_messages do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0        # enum: user=0, assistant=1
      t.text :content, null: false
      t.integer :source_feedback_ids, array: true, default: []  # IDs of feedbacks used as RAG context
      t.timestamps
    end

    add_index :chat_messages, [:account_id, :created_at]
    add_index :chat_messages, [:user_id, :created_at]
  end
end
