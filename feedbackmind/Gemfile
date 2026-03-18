source "https://rubygems.org"

ruby "~> 3.2"

gem "rails", "~> 7.2"

# Core
gem "pg", "~> 1.5"
gem "puma", ">= 6.0"
gem "redis", ">= 5.0"

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

# Billing
gem "stripe", "~> 12.0"

# Email
gem "postmark-rails", "~> 0.22"

# Deployment
gem "kamal", "~> 2.0"
gem "thruster", "~> 0.1"

# Utilities
gem "bootsnap", require: false
gem "tzinfo-data", platforms: [:windows, :jruby]

group :development, :test do
  gem "rspec-rails", "~> 7.0"
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
  gem "annotate", "~> 3.2"
end

group :test do
  gem "shoulda-matchers", "~> 6.0"
  gem "webmock", "~> 3.23"
  gem "vcr", "~> 6.3"
  gem "simplecov", require: false
  gem "capybara"
  gem "selenium-webdriver"
end
