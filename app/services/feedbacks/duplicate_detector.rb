module Feedbacks
  class DuplicateDetector
    SIMILARITY_THRESHOLD = 0.12 # cosine distance — lower = more similar

    def initialize(account)
      @account = account
    end

    # Find potential duplicates for a single feedback
    def find_duplicates(feedback, limit: 5)
      return [] unless feedback.has_embedding?

      candidates = @account.feedbacks
                        .where.not(id: feedback.id)
                        .with_embedding
                        .nearest_to(feedback.embedding, limit: limit)

      candidates.select do |candidate|
        distance = candidate.neighbor_distance
        distance < SIMILARITY_THRESHOLD
      end
    end

    # Scan all feedbacks and return groups of duplicates
    def scan_all(limit_per: 3)
      groups = []
      seen_ids = Set.new

      @account.feedbacks.with_embedding.order(received_at: :desc).find_each do |feedback|
        next if seen_ids.include?(feedback.id)

        duplicates = find_duplicates(feedback, limit: limit_per)
        next if duplicates.empty?

        group_ids = [feedback.id] + duplicates.map(&:id)
        next if group_ids.any? { |id| seen_ids.include?(id) }

        groups << {
          primary: feedback,
          duplicates: duplicates,
          count: duplicates.size + 1
        }
        seen_ids.merge(group_ids)
      end

      groups
    end
  end
end
