# PROMPT 19 — Tests + Final Verification

Write request specs for all web controllers and verify everything works end-to-end.

## Task 1: Create test helpers

### spec/support/auth_helpers.rb
```ruby
module AuthHelpers
  def sign_in_user(user = nil)
    user ||= create(:user)
    sign_in user
    ActsAsTenant.current_tenant = user.account
    user
  end
end

RSpec.configure do |config|
  config.include AuthHelpers
  config.include Devise::Test::IntegrationHelpers, type: :request
end
```

### Update spec/rails_helper.rb to require support files:
```ruby
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
```

## Task 2: Create factories (if not already done)

### spec/factories/accounts.rb
```ruby
FactoryBot.define do
  factory :account do
    name { Faker::Company.name }
    subdomain { Faker::Internet.slug }
    plan { :growth }
    onboarding_completed { true }
  end
end
```

### spec/factories/users.rb
```ruby
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "password123" }
    role { :owner }
    association :account
  end
end
```

### spec/factories/feedbacks.rb
```ruby
FactoryBot.define do
  factory :feedback do
    content { Faker::Lorem.paragraph(sentence_count: 3) }
    external_id { SecureRandom.uuid }
    sentiment { [:positive, :negative, :neutral].sample }
    topics { [%w[payments checkout mobile search ux].sample(2)] }
    association :account
    association :source
  end
end
```

### spec/factories/sources.rb
```ruby
FactoryBot.define do
  factory :source do
    name { "Test Source" }
    source_type { :intercom }
    active { true }
    association :account
  end
end
```

### spec/factories/weekly_syntheses.rb
```ruby
FactoryBot.define do
  factory :weekly_synthesis do
    week_start { 1.week.ago.beginning_of_week }
    week_end { 1.week.ago.end_of_week }
    feedback_count { 25 }
    themes { [{ title: "Test Theme", urgency: "high", description: "Test", feedback_count: 10 }] }
    summary { "Test synthesis summary" }
    association :account
  end
end
```

## Task 3: Write request specs

### spec/requests/dashboard_spec.rb
```ruby
require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { sign_in user }

  describe "GET /dashboard" do
    it "returns success" do
      get dashboard_path
      expect(response).to have_http_status(:ok)
    end

    it "shows feedback count" do
      create_list(:feedback, 5, account: account, source: create(:source, account: account))
      get dashboard_path
      expect(response.body).to include("5")
    end

    it "respects period parameter" do
      get dashboard_path(period: 30)
      expect(response).to have_http_status(:ok)
    end

    it "redirects to onboarding if not completed" do
      account.update!(onboarding_completed: false)
      get dashboard_path
      expect(response).to redirect_to(onboarding_path)
    end
  end
end
```

### spec/requests/feedbacks_spec.rb
```ruby
require "rails_helper"

RSpec.describe "Feedbacks", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:source) { create(:source, account: account) }

  before { sign_in user }

  describe "GET /feedbacks" do
    it "returns success" do
      get feedbacks_path
      expect(response).to have_http_status(:ok)
    end

    it "filters by sentiment" do
      create(:feedback, account: account, source: source, sentiment: :positive)
      create(:feedback, account: account, source: source, sentiment: :negative)
      get feedbacks_path(sentiment: "positive")
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /feedbacks/:id" do
    it "shows feedback details" do
      feedback = create(:feedback, account: account, source: source)
      get feedback_path(feedback)
      expect(response).to have_http_status(:ok)
    end
  end
end
```

### spec/requests/syntheses_spec.rb
```ruby
require "rails_helper"

RSpec.describe "Syntheses", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { sign_in user }

  describe "GET /syntheses" do
    it "returns success" do
      get syntheses_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /syntheses" do
    it "enqueues synthesis job" do
      expect {
        post syntheses_path
      }.to have_enqueued_job(WeeklySynthesisJob)
      expect(response).to redirect_to(syntheses_path)
    end
  end
end
```

### Write similar specs for:
- spec/requests/sources_spec.rb (index, show, create, destroy)
- spec/requests/pipeline_spec.rb (show)
- spec/requests/loop_tracker_spec.rb (show)
- spec/requests/settings_spec.rb (show, update, regenerate_token)
- spec/requests/chat_spec.rb (create with plan check)
- spec/requests/onboarding_spec.rb (show, update, skip)
- spec/requests/pages_spec.rb (home without auth)

Each spec should test:
1. Authentication required (redirect to sign_in if not logged in)
2. Success response for authenticated users
3. Tenant isolation (can't see other account's data)
4. Key business logic (filters, pagination, plan gates)

## Task 4: Run all tests
```bash
bundle exec rspec --format documentation
```

Expected: All specs pass. Both the existing API specs and the new web specs.

## Task 5: Full end-to-end verification
```bash
# 1. Reset and seed
rails db:reset
rails db:seed

# 2. Compile assets
rails tailwindcss:build
rails assets:precompile

# 3. Start Sidekiq
bundle exec sidekiq &

# 4. Start server
rails server

# 5. Test manually:
# - Visit http://localhost:3000 (landing page)
# - Sign up new user
# - Complete onboarding
# - Visit dashboard (real data from seeds)
# - Navigate all pages
# - Try AI chat
# - Try filters on feedbacks
# - Check settings/billing
# - Test command palette (Cmd+K)
```

## Task 6: Fix any remaining issues found during testing
This is the cleanup prompt. Fix any:
- Missing partials
- Undefined helper methods
- N+1 queries (add includes/eager_load)
- Missing routes
- Stimulus controllers not connecting
- CSS not applying
- Flash messages not showing
- Turbo not working properly
