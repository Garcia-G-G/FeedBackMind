module Webhooks
  class BaseController < ActionController::API
    before_action :read_raw_body

    private

    def read_raw_body
      @raw_body = request.body.read
      request.body.rewind
    end

    def find_source(account, source_type)
      account.sources.active.find_by!(source_type: source_type)
    end

    def enqueue_feedback(account_id, source_id, raw_data)
      FeedbackIngestJob.perform_async(account_id, source_id, raw_data)
    end

    def verify_signature_or_reject!(computed, received)
      unless ActiveSupport::SecurityUtils.secure_compare(computed, received.to_s)
        render json: { error: "Invalid signature", code: "unauthorized" }, status: :unauthorized
        return false
      end
      true
    end

    def head_ok
      head :ok
    end
  end
end
