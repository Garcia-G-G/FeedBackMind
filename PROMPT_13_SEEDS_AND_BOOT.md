# PROMPT 13 — Seed Data + Boot Verification

The app needs real seed data so we can see the dashboard working with actual records. Create comprehensive seeds and verify the app boots cleanly.

## Task 1: Create db/seeds.rb

Create seed data that populates:

### 1. Account
```ruby
account = Account.create!(
  name: "FeedbackMind Demo",
  subdomain: "demo",
  plan: "growth",
  feedbacks_count_this_month: 0
)
account.generate_api_token!
```

### 2. User (owner)
```ruby
user = User.create!(
  email: "garcia@feedbackmind.com",
  password: "password123",
  password_confirmation: "password123",
  account: account,
  role: :owner
)
```

### 3. Sources (6 active sources)
```ruby
sources_data = [
  { name: "Intercom Chat", source_type: :intercom, active: true },
  { name: "Customer Surveys", source_type: :typeform, active: true },
  { name: "Bug Tracker", source_type: :jira, active: true },
  { name: "Team Channel", source_type: :slack, active: true },
  { name: "Support Email", source_type: :gmail, active: true },
  { name: "iOS Reviews", source_type: :app_store, active: true }
]
sources = sources_data.map { |data| Source.create!(account: account, **data) }
```

### 4. Feedbacks (50+ diverse feedbacks)
Create 50 feedbacks with realistic content covering:
- Various sentiments (60% positive, 25% neutral, 15% negative)
- Various topics: ["payments", "checkout", "mobile", "search", "onboarding", "performance", "design", "ux", "export", "api", "pricing", "support"]
- Distributed across all 6 sources
- Created at various times over the past 14 days
- Some processed (with sentiment + topics set), some unprocessed
- Realistic content text (2-3 sentences each, mix of complaints, praise, feature requests)
- Set `external_id` to avoid uniqueness issues

Use Faker gem for variety but make the content relevant to a SaaS product. Example content:
- Negative: "Payment keeps failing on mobile. Tried 3 cards, none work. Very frustrating."
- Positive: "The new onboarding flow is amazing. Had everything set up in under 5 minutes."
- Neutral: "Would be great to have bulk export for reports. Currently downloading one by one."

### 5. WeeklySynthesis (2 weeks)
Create 2 weekly syntheses with realistic JSONB data:
```ruby
WeeklySynthesis.create!(
  account: account,
  week_start: 1.week.ago.beginning_of_week,
  week_end: 1.week.ago.end_of_week,
  feedback_count: 35,
  themes: [
    {
      title: "Checkout flow frustrations",
      urgency: "critical",
      description: "Multiple users reporting payment failures on mobile devices",
      feedback_count: 12,
      sources: ["intercom", "typeform"],
      action_items: ["Add error messages to payment step", "Test mobile payment flow"]
    },
    {
      title: "Search relevance improvements needed",
      urgency: "high",
      description: "Search results not matching user intent for specific queries",
      feedback_count: 8,
      sources: ["slack", "jira"],
      action_items: ["Implement fuzzy matching", "Add search suggestions"]
    },
    {
      title: "Onboarding praised by new users",
      urgency: "positive",
      description: "Great feedback about the guided setup flow",
      feedback_count: 15,
      sources: ["app_store", "gmail"],
      action_items: ["Continue iterating on onboarding", "Add more tooltips"]
    }
  ],
  summary: "This week saw 35 feedbacks across 6 sources. Checkout issues are the top risk with 12 reports. Onboarding continues to receive positive feedback.",
  risks: [{ title: "Checkout abandonment", severity: "high", feedback_count: 12 }],
  quick_wins: [
    { title: "Add payment error messages", impact: "high", effort: "low" },
    { title: "Search empty state suggestions", impact: "medium", effort: "medium" }
  ]
)
```

Create a second synthesis for 2 weeks ago with different data.

### 6. ChatMessages (sample conversation)
```ruby
ChatMessage.create!(account: account, role: :user, content: "What are users saying about checkout?")
ChatMessage.create!(account: account, role: :assistant, content: "Based on 12 recent feedbacks, the main checkout complaints are: payment failures on mobile (8 reports), too many steps (3 reports), and session timeouts (1 report). The estimated MRR at risk is $12,400.")
```

## Task 2: Run seeds
```bash
rails db:seed
```

## Task 3: Verify app boots
```bash
rails runner "puts Account.count; puts User.count; puts Feedback.count; puts Source.count; puts WeeklySynthesis.count"
```
Expected: 1 account, 1 user, 50+ feedbacks, 6 sources, 2 syntheses.

## Task 4: Verify eager loading
```bash
rails runner 'Rails.application.eager_load!; puts "All OK"'
```

## Task 5: Run existing specs
```bash
bundle exec rspec --format progress
```

## Task 6: Start server and verify
```bash
rails server -p 3000
```
Visit http://localhost:3000 — should see landing page.
Login with garcia@feedbackmind.com / password123 — should see dashboard with real data.
