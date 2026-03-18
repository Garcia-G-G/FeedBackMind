class AddEmbeddingToFeedbacks < ActiveRecord::Migration[7.2]
  def change
    # Add vector column for pgvector embeddings (1536 dimensions = text-embedding-3-small)
    add_column :feedbacks, :embedding, :vector, limit: 1536

    # HNSW index — superior to IVFFlat for production:
    # - 40.5 QPS vs 2.6 QPS on 1M vectors
    # - Can be created on empty tables (no training data required)
    # - Better recall at same speed
    # - Scales logarithmically with data size
    add_index :feedbacks, :embedding,
              using: :hnsw,
              opclass: :vector_cosine_ops,
              name: "index_feedbacks_on_embedding_hnsw"
  end
end
