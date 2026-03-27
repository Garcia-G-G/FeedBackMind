class AddTagsToFeedbacks < ActiveRecord::Migration[7.2]
  def change
    add_column :feedbacks, :tags, :string, array: true, default: []
    add_index :feedbacks, :tags, using: :gin
  end
end
