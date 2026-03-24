OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_API_KEY", nil) || Rails.application.credentials.dig(:openai, :api_key)
  config.log_errors = Rails.env.development?
end
