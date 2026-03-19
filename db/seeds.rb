puts "Seeding FeedbackMind development data..."

# === 1. Account ===
account = Account.find_or_create_by!(subdomain: "demo") do |a|
  a.name = "FeedbackMind Demo"
  a.plan = :growth
  a.feedback_count_this_month = 0
end
account.regenerate_api_token! if account.api_token.blank?
puts "  Account: #{account.name} (#{account.plan}) — API Token: #{account.api_token}"

# === 2. User (owner) ===
user = User.find_or_create_by!(email: "garcia@feedbackmind.com") do |u|
  u.account = account
  u.name = "Garcia"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :owner
end
puts "  User: #{user.email} / password123"

# === 3. Sources (6 active) ===
sources_data = [
  { source_type: :intercom, active: true, config: { "webhook_secret" => "whsec_demo_intercom" } },
  { source_type: :typeform, active: true, config: { "webhook_secret" => "whsec_demo_typeform" } },
  { source_type: :jira, active: true, config: {} },
  { source_type: :slack, active: true, config: { "signing_secret" => "demo_slack_secret", "team_id" => "T12345" } },
  { source_type: :gmail, active: true, config: {} },
  { source_type: :appstore, active: true, config: { "app_id" => "com.feedbackmind.app" } }
]

sources = sources_data.map do |data|
  Source.find_or_create_by!(account: account, source_type: data[:source_type]) do |s|
    s.active = data[:active]
    s.config = data[:config]
  end
end
puts "  Sources: #{sources.count} created"

# === 4. Feedbacks (50+ diverse) ===
ActsAsTenant.with_tenant(account) do
  feedback_samples = [
    # Negative — payments/checkout (12)
    { content: "Payment keeps failing on mobile. Tried 3 cards, none work. Very frustrating.", sentiment: :negative, topics: ["payments", "mobile", "checkout"], author_name: "Sarah K." },
    { content: "The checkout process has too many steps. By step 4, I almost abandoned my purchase.", sentiment: :negative, topics: ["checkout", "ux"], author_name: "David L." },
    { content: "Mobile payment form is broken on Safari. The submit button doesn't respond.", sentiment: :negative, topics: ["mobile", "payments", "checkout"], author_name: "Emma R." },
    { content: "Session timed out during checkout. Lost all my cart items. Really annoying.", sentiment: :negative, topics: ["checkout", "performance"], author_name: "James W." },
    { content: "Card validation error is unclear — just says 'invalid'. Which field is wrong?", sentiment: :negative, topics: ["payments", "ux"], author_name: "Lisa M." },
    { content: "Apple Pay integration doesn't work. Just shows a blank modal.", sentiment: :negative, topics: ["payments", "mobile"], author_name: "Tom B." },
    { content: "I had to enter my address twice during checkout. The form reset after payment step.", sentiment: :negative, topics: ["checkout", "ux"], author_name: "Anna P." },
    { content: "The discount code field is hidden behind a tiny link. Took me 5 minutes to find it.", sentiment: :negative, topics: ["checkout", "design"], author_name: "Kevin H." },
    # Negative — search/performance
    { content: "Search returns irrelevant results. I searched for 'billing' and got articles about 'building'.", sentiment: :negative, topics: ["search", "ux"], author_name: "Nina S." },
    { content: "Dashboard takes 6 seconds to load. Way too slow for a daily tool.", sentiment: :negative, topics: ["performance", "dashboard"], author_name: "Alex T." },
    { content: "The API rate limits are too low for our integration. Hitting 429s during peak.", sentiment: :negative, topics: ["api", "performance"], author_name: "Chris F." },
    # Positive — onboarding (15)
    { content: "The new onboarding flow is amazing. Had everything set up in under 5 minutes.", sentiment: :positive, topics: ["onboarding", "ux"], author_name: "Mike R." },
    { content: "Love how the setup wizard walks you through connecting sources. Very intuitive.", sentiment: :positive, topics: ["onboarding", "ux"], author_name: "Rachel G." },
    { content: "The guided tour was super helpful. Understood the product in minutes.", sentiment: :positive, topics: ["onboarding"], author_name: "Ben D." },
    { content: "Just signed up. The welcome email had great tips. Already connected 3 sources.", sentiment: :positive, topics: ["onboarding", "support"], author_name: "Olivia J." },
    { content: "Best onboarding I've seen in a B2B tool. No confusion, no friction.", sentiment: :positive, topics: ["onboarding", "ux"], author_name: "Jake M." },
    { content: "The interactive tooltips during setup are brilliant. Didn't need to read any docs.", sentiment: :positive, topics: ["onboarding", "design"], author_name: "Sophie L." },
    # Positive — features
    { content: "The AI chat feature is incredibly useful. Asked about billing issues and got a detailed summary.", sentiment: :positive, topics: ["chat", "ai"], author_name: "Emma W." },
    { content: "Weekly synthesis saves me hours every Monday. The executive summary is perfect for stakeholders.", sentiment: :positive, topics: ["synthesis", "productivity"], author_name: "Amy C." },
    { content: "The command palette (Cmd+K) is super fast. Feels like using Linear.", sentiment: :positive, topics: ["ux", "command-palette"], author_name: "Mark T." },
    { content: "Love the sentiment timeline. Finally can see trends over time, not just pie charts.", sentiment: :positive, topics: ["dashboard", "design"], author_name: "Laura K." },
    { content: "The theme clustering is spot on. It grouped related feedbacks that I would have missed.", sentiment: :positive, topics: ["ai", "synthesis"], author_name: "Ryan P." },
    { content: "Pricing is fair for what you get. Growth plan has everything our team needs.", sentiment: :positive, topics: ["pricing"], author_name: "Helen V." },
    { content: "The Slack integration works seamlessly. Feedbacks flow in without any manual work.", sentiment: :positive, topics: ["integrations", "slack"], author_name: "Daniel N." },
    { content: "Our team switched from Productboard. The AI synthesis is leagues ahead.", sentiment: :positive, topics: ["comparison", "synthesis"], author_name: "Nina S." },
    { content: "The feedback pipeline view is exactly what we needed. Clear visual of the process.", sentiment: :positive, topics: ["pipeline", "ux"], author_name: "Peter Q." },
    { content: "Just got our first weekly digest email. The formatting is clean and actionable.", sentiment: :positive, topics: ["synthesis", "design"], author_name: "Grace H." },
    { content: "Sentiment analysis is accurate. It even catches subtle frustration in polite messages.", sentiment: :positive, topics: ["ai", "sentiment"], author_name: "Kate B." },
    # Neutral — feature requests
    { content: "Would be great to have bulk export for reports. Currently downloading one by one.", sentiment: :neutral, topics: ["export", "feature-request"], author_name: "Chris L." },
    { content: "Export to PDF would be helpful for our monthly stakeholder reports.", sentiment: :neutral, topics: ["export", "feature-request"], author_name: "Amy C." },
    { content: "I'd like to tag feedbacks manually in addition to the AI-generated topics.", sentiment: :neutral, topics: ["tagging", "feature-request"], author_name: "Tom H." },
    { content: "A mobile app would be nice for checking the dashboard on the go.", sentiment: :neutral, topics: ["mobile", "feature-request"], author_name: "Kevin F." },
    { content: "Can you add Zendesk as a source? That's our primary support tool.", sentiment: :neutral, topics: ["integrations", "feature-request"], author_name: "Lisa M." },
    { content: "Would love to set up custom alerts when sentiment drops below a threshold.", sentiment: :neutral, topics: ["alerts", "feature-request"], author_name: "James B." },
    { content: "The filtering could be better. Need to filter by date range AND source at the same time.", sentiment: :neutral, topics: ["filtering", "ux"], author_name: "Olivia J." },
    { content: "Dark mode would be a nice addition. I use this tool late in the evening.", sentiment: :neutral, topics: ["design", "feature-request"], author_name: "Sam W." },
    { content: "Is there a way to share a synthesis report with someone outside the team?", sentiment: :neutral, topics: ["sharing", "feature-request"], author_name: "Maria D." },
    { content: "The API docs could use more examples. The authentication section was a bit unclear.", sentiment: :neutral, topics: ["api", "documentation"], author_name: "Rob T." },
    # More positive
    { content: "Support team response was lightning fast. Issue resolved in under an hour.", sentiment: :positive, topics: ["support"], author_name: "Janet R." },
    { content: "The closed-loop tracker is brilliant. We can finally show users their feedback led to changes.", sentiment: :positive, topics: ["loop-tracker", "ux"], author_name: "Steve C." },
    { content: "Data import via CSV was smooth. 2000 rows imported in seconds.", sentiment: :positive, topics: ["csv-import"], author_name: "Diana F." },
    # More negative
    { content: "The mobile experience needs work. Hard to read the dashboard on my phone.", sentiment: :negative, topics: ["mobile", "ux"], author_name: "Kevin F." },
    { content: "CSV import broke when my file had special characters in the author name column.", sentiment: :negative, topics: ["csv-import", "bugs"], author_name: "David P." },
    # Additional variety
    { content: "Just discovered the RAG chat. Asked 'what do users think about pricing?' and got a perfect answer with sources cited.", sentiment: :positive, topics: ["chat", "ai"], author_name: "Taylor S." },
    { content: "The Intercom webhook setup was straightforward. Connected in 2 minutes.", sentiment: :positive, topics: ["integrations", "onboarding"], author_name: "Chris A." },
    { content: "Would be useful to see feedback volume over time, not just the current week.", sentiment: :neutral, topics: ["dashboard", "feature-request"], author_name: "Pat M." },
    { content: "Search is too basic. Need full-text search with AND/OR operators.", sentiment: :neutral, topics: ["search", "feature-request"], author_name: "Jordan K." },
    { content: "The role-based views are handy. My engineering lead sees different cards than I do.", sentiment: :positive, topics: ["ux", "roles"], author_name: "Casey W." },
    { content: "Got a 500 error when trying to view a deleted source's feedbacks.", sentiment: :negative, topics: ["bugs"], author_name: "Morgan R." },
  ]

  feedback_samples.each_with_index do |data, i|
    source = sources[i % sources.length]
    Feedback.find_or_create_by!(account: account, source: source, external_id: "seed_#{i + 1}") do |f|
      f.content = data[:content]
      f.sentiment = data[:sentiment]
      f.topics = data[:topics]
      f.author_name = data[:author_name]
      f.author_email = data[:author_name]&.downcase&.gsub(/[^a-z]/, "") + "@example.com"
      f.received_at = rand(1..14).days.ago + rand(0..23).hours
      f.processed_at = i < 45 ? rand(0..12).days.ago : nil  # Last 5 unprocessed
      f.metadata = {}
    end
  end
  puts "  Feedbacks: #{account.feedbacks.count} total"

  # === 5. WeeklySyntheses (2 weeks) ===
  WeeklySynthesis.find_or_create_by!(account: account, week_start: 1.week.ago.beginning_of_week(:monday)) do |ws|
    ws.feedback_count = 35
    ws.executive_summary = "This week saw 35 feedbacks across 6 sources. Checkout issues are the top risk with 12 reports. Onboarding continues to receive positive feedback. Feature requests for export and integrations are growing."
    ws.top_themes = [
      { "title" => "Checkout flow frustrations", "urgency" => "critical", "description" => "Multiple users reporting payment failures on mobile devices", "feedback_count" => 12, "sample_quotes" => ["Payment keeps failing on mobile", "Session timed out during checkout"], "suggested_action" => "Add error messages to payment step, test mobile payment flow" },
      { "title" => "Search relevance improvements", "urgency" => "high", "description" => "Search results not matching user intent for specific queries", "feedback_count" => 8, "sample_quotes" => ["Searched for billing and got articles about building"], "suggested_action" => "Implement fuzzy matching and search suggestions" },
      { "title" => "Onboarding praised by new users", "urgency" => "low", "description" => "Great feedback about the guided setup flow", "feedback_count" => 15, "sample_quotes" => ["Best onboarding I've seen in a B2B tool"], "suggested_action" => "Continue iterating on onboarding, add more tooltips" }
    ]
    ws.biggest_risk = { "theme" => "Checkout abandonment", "potential_impact" => "Estimated $12,400 MRR at risk from 12 checkout-related complaints" }
    ws.quick_wins = ["Add payment error messages", "Search empty state suggestions", "Mobile checkout testing"]
    ws.sent_at = 6.days.ago
  end

  WeeklySynthesis.find_or_create_by!(account: account, week_start: 2.weeks.ago.beginning_of_week(:monday)) do |ws|
    ws.feedback_count = 28
    ws.executive_summary = "Quieter week with 28 feedbacks. API and performance concerns emerged. Positive sentiment around AI features remains strong. Two new integration requests (Zendesk, custom alerts)."
    ws.top_themes = [
      { "title" => "API rate limiting concerns", "urgency" => "high", "description" => "Enterprise customers hitting rate limits during peak hours", "feedback_count" => 5, "sample_quotes" => ["Hitting 429 errors during peak hours"], "suggested_action" => "Review rate limit tiers for Growth/Scale plans" },
      { "title" => "Dashboard performance", "urgency" => "high", "description" => "Dashboard slow for accounts with 500+ feedbacks", "feedback_count" => 4, "sample_quotes" => ["Dashboard takes 6 seconds to load"], "suggested_action" => "Add pagination and query optimization" },
      { "title" => "AI features well received", "urgency" => "low", "description" => "Strong positive sentiment for chat and synthesis features", "feedback_count" => 10, "sample_quotes" => ["The AI chat feature is incredibly useful"], "suggested_action" => "Expand AI capabilities, consider auto-generated PRDs" }
    ]
    ws.biggest_risk = { "theme" => "Enterprise churn risk", "potential_impact" => "API limitations may cause 2 Scale customers to evaluate alternatives" }
    ws.quick_wins = ["Increase rate limits for Scale plan", "Add dashboard loading skeleton", "Cache frequent queries"]
    ws.sent_at = 13.days.ago
  end
  puts "  Weekly syntheses: #{account.weekly_syntheses.count} created"

  # === 6. ChatMessages (sample conversation) ===
  ChatMessage.find_or_create_by!(account: account, user: user, role: :user, content: "What are users saying about checkout?") do |m|
    m.source_feedback_ids = []
  end
  ChatMessage.find_or_create_by!(account: account, user: user, role: :assistant, content: "Based on 12 recent feedbacks, the main checkout complaints are:\n\n1. **Payment failures on mobile** (8 reports) — Users report cards being declined and Apple Pay showing blank modals\n2. **Too many steps** (3 reports) — Users find the multi-step flow cumbersome\n3. **Session timeouts** (1 report) — Cart data lost during checkout\n\nThe estimated MRR at risk is **$12,400**. I'd recommend prioritizing mobile payment testing and reducing checkout steps.") do |m|
    m.source_feedback_ids = account.feedbacks.where("content ILIKE ?", "%checkout%").limit(5).pluck(:id)
  end
  puts "  Chat messages: #{account.chat_messages.count} created"
end

puts ""
puts "Seed complete!"
puts "  Login: garcia@feedbackmind.com / password123"
puts "  URL:   http://localhost:3500"
puts "  API:   Bearer #{account.api_token}"
