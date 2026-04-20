source "https://rubygems.org"

ruby "~> 3.2"

gem "rails", "~> 8.0"

# Core
gem "pg", "~> 1.5"
gem "puma", ">= 6.0"
gem "redis", ">= 5.0"
gem "connection_pool", "~> 2.4"

# Frontend (Hotwire)
gem "turbo-rails", "~> 2.0"
gem "stimulus-rails", "~> 1.3"
gem "tailwindcss-rails", "~> 2.7"
gem "sprockets-rails"

# Background Jobs
gem "sidekiq", "~> 7.3"
gem "sidekiq-cron", "~> 2.0"

# AI & Vector Search
gem "ruby-openai", "~> 7.3"
gem "neighbor", "~> 0.4"

# Authentication & Multi-tenancy
gem "devise", "~> 5.0"
gem "acts_as_tenant", "~> 1.0"
gem "omniauth", "~> 2.1"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "omniauth-slack-openid", "~> 1.2"
gem "omniauth-google-oauth2", "~> 1.1"
gem "oauth2", "~> 2.0"

# Billing
gem "stripe", "~> 12.0"

# Email
gem "resend", "~> 0.17"
gem "postmark-rails", "~> 0.22"

# Deployment
gem "kamal", "~> 2.0"
gem "thruster", "~> 0.1"

# CSV (removed from default gems in Ruby 3.4)
gem "csv"

# Security
gem "rack-attack", "~> 6.7"

# Utilities
gem "bootsnap", require: false
gem "tzinfo-data", platforms: [:windows, :jruby]

group :development, :test do
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.4"
  gem "dotenv-rails", "~> 3.1"
  gem "debug", platforms: [:mri, :windows, :mswin]
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
  gem "letter_opener", "~> 1.10"
  # gem "annotate" — removed, incompatible with Rails 8
end

group :test do
  gem "shoulda-matchers", "~> 6.0"
  gem "webmock", "~> 3.23"
  gem "vcr", "~> 6.3"
  gem "simplecov", require: false
  gem "capybara"
  gem "selenium-webdriver"
end
