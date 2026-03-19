module AuthHelpers
  def sign_in_as(user)
    sign_in user
    ActsAsTenant.current_tenant = user.account
  end

  def api_headers(account_or_token = nil)
    token = case account_or_token
            when Account then account_or_token.api_token
            when String then account_or_token
            else ""
            end
    { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
