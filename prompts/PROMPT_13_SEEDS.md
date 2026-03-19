# PROMPT 13 — Seed Data + Boot Verification

Create comprehensive seed data so the app works with real records. Then verify the app boots.

## Create db/seeds.rb

Populate with:

### 1. Account
- name: "FeedbackMind Demo", subdomain: "demo", plan: "growth", feedbacks_count_this_month: 0
- Call generate_api_token! after creation

### 2. User (owner)
- email: "garcia@feedbackmind.com", password: "password123", role: :owner, linked to account

### 3. Sources (6 active)
Create one of each: intercom ("Intercom Chat"), typeform ("Customer Surveys"), jira ("Bug Tracker"), slack ("Team Channel"), gmail ("Support Email"), app_store ("iOS Reviews"). All active: true.

### 4. Feedbacks (50+ diverse)
Create 50 feedbacks with:
- Realistic SaaS feedback content (2-3 sentences each)
- 60% positive, 25% neutral, 15% negative sentiment
- Topics from: payments, checkout, mobile, search, onboarding, performance, design, ux, export, api, pricing, support
- Distributed across all 6 sources
- created_at spread across last 14 days (use rand(0..14).days.ago)
- Most should be processed (sentiment + topics set), ~10 unprocessed (sentiment: nil)
- Each needs unique external_id (use "seed_#{SecureRandom.hex(8)}")
- Use Faker for variety but keep content relevant to a SaaS product

Example content:
- Negative: "Payment keeps failing on mobile. Tried 3 different cards and none work. Very frustrating experience."
- Positive: "The new onboarding flow is fantastic. Had everything connected in under 5 minutes. Great job!"
- Neutral: "Would be nice to have bulk export for reports. Currently downloading them one by one."
- Negative: "Search results are completely irrelevant when searching for specific product names."
- Positive: "Dashboard redesign looks great, much cleaner and easier to navigate."

### 5. WeeklySyntheses (2 weeks)
Create 2 syntheses with realistic JSONB themes data:

Week 1 (1.week.ago): 3 themes — "Checkout flow frustrations" (critical, 12 feedbacks, MRR risk $12400), "Search relevance improvements" (high, 8 feedbacks), "Onboarding praised" (positive, 15 feedbacks). Include summary, risks array, quick_wins array.

Week 2 (2.weeks.ago): 3 different themes with different data.

### 6. ChatMessages (sample conversation)
2 messages: user asks "What are users saying about checkout?", assistant responds with detailed answer citing feedback counts.

## After creating seeds, run:
```bash
rails db:seed
rails runner "puts 'Accounts: ' + Account.count.to_s; puts 'Users: ' + User.count.to_s; puts 'Feedbacks: ' + Feedback.count.to_s; puts 'Sources: ' + Source.count.to_s; puts 'Syntheses: ' + WeeklySynthesis.count.to_s"
```

Expected: 1 account, 1 user, 50+ feedbacks, 6 sources, 2 syntheses.

## Then verify:
```bash
rails runner 'Rails.application.eager_load!; puts "All OK"'
bundle exec rspec --format progress
rails server -p 3000
```

Login: garcia@feedbackmind.com / password123
