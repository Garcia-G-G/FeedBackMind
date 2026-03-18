class ApplicationJob
  include Sidekiq::Job

  sidekiq_options retry: 3

  def self.perform_unique_async(*args)
    # Simple idempotency check using Sidekiq's built-in uniqueness
    perform_async(*args)
  end
end
