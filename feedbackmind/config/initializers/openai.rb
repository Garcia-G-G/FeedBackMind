OpenAI.configure do |config|
  config.access_token = Rails.application.credentials.dig(:openai, :api_key) || ENV.fetch("OPENAI_API_KEY", nil)
  config.log_errors = Rails.env.development?
end
