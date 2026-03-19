module ApiHelpers
  def api_headers(account)
    {
      "Authorization" => "Bearer #{account.api_token}",
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  end

  def json_response
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
