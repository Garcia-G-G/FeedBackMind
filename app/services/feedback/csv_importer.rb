require "csv"

module Feedback
  class CsvImporter
    REQUIRED_HEADERS = %w[content].freeze
    MAX_ROWS = 10_000

    def initialize(account:, source_id:)
      @account = account
      @source_id = source_id
    end

    # Import a CSV file and enqueue feedback jobs
    # Returns { enqueued: Integer, skipped: Integer, errors: Array }
    def import(file)
      csv = parse_csv(file)
      validate_headers!(csv.headers)

      source = @account.sources.find(@source_id)
      enqueued = 0
      skipped = 0
      errors = []

      csv.each_with_index do |row, index|
        if index >= MAX_ROWS
          errors << "Row limit reached (#{MAX_ROWS}). Remaining rows skipped."
          break
        end

        content = row["content"]&.strip
        if content.blank?
          skipped += 1
          next
        end

        FeedbackIngestJob.perform_async(@account.id, source.id, {
          external_id: row["external_id"] || row["id"],
          content: content,
          author_email: row["author_email"] || row["email"],
          author_name: row["author_name"] || row["name"] || row["author"],
          metadata: extract_metadata(row),
          received_at: row["received_at"] || row["date"] || row["created_at"]
        })

        enqueued += 1
      rescue => e
        errors << "Row #{index + 2}: #{e.message}"
        skipped += 1
      end

      { enqueued: enqueued, skipped: skipped, errors: errors }
    end

    private

    def parse_csv(file)
      content = file.respond_to?(:read) ? file.read : file
      CSV.parse(content, headers: true, liberal_parsing: true)
    end

    def validate_headers!(headers)
      missing = REQUIRED_HEADERS - headers.map(&:to_s).map(&:strip).map(&:downcase)
      if missing.any?
        raise ArgumentError, "Missing required CSV headers: #{missing.join(', ')}"
      end
    end

    def extract_metadata(row)
      known_fields = %w[content external_id id author_email email author_name name author received_at date created_at]
      extra = row.to_h.except(*known_fields).compact
      extra.presence || {}
    end
  end
end
