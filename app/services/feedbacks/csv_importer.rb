require "csv"

module Feedbacks
  class CsvImporter
    REQUIRED_HEADERS = %w[content].freeze
    OPTIONAL_HEADERS = %w[author_email author_name external_id received_at].freeze
    MAX_ROWS = 5_000

    def initialize(account:, source:, file:)
      @account = account
      @source = source
      @file = file
    end

    # Parses CSV and enqueues FeedbackIngestJob for each valid row
    # Returns { enqueued: Integer, skipped: Integer, errors: Array<String> }
    def import
      result = { enqueued: 0, skipped: 0, errors: [] }

      begin
        csv = CSV.parse(@file.read, headers: true, liberal_parsing: true)
      rescue CSV::MalformedCSVError => e
        result[:errors] << "CSV parsing error: #{e.message}"
        return result
      end

      # Validate headers
      unless (REQUIRED_HEADERS - csv.headers).empty?
        result[:errors] << "Missing required column: content. Found headers: #{csv.headers.join(', ')}"
        return result
      end

      csv.each_with_index do |row, index|
        if index >= MAX_ROWS
          result[:errors] << "CSV exceeds maximum of #{MAX_ROWS} rows. Remaining rows skipped."
          break
        end

        content = row["content"]&.strip
        if content.blank?
          result[:skipped] += 1
          next
        end

        # Check plan limits
        if @account.feedback_limit_reached?
          result[:errors] << "Feedback limit reached at row #{index + 1}. Upgrade your plan for more."
          break
        end

        FeedbackIngestJob.perform_async(
          @account.id,
          @source.id,
          {
            "external_id" => row["external_id"]&.strip.presence || "csv_#{SecureRandom.hex(8)}",
            "content" => content,
            "author_email" => row["author_email"]&.strip,
            "author_name" => row["author_name"]&.strip,
            "metadata" => row.to_h.except(*REQUIRED_HEADERS, *OPTIONAL_HEADERS).compact,
            "received_at" => parse_date(row["received_at"]) || Time.current.iso8601
          }
        )

        result[:enqueued] += 1
      end

      result
    end

    private

    def parse_date(value)
      return nil unless value.present?
      Time.parse(value).iso8601
    rescue ArgumentError
      nil
    end
  end
end
