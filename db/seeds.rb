puts "Seeding FeedbackMind development data..."

# Create demo account
account = Account.find_or_create_by!(subdomain: "demo-team") do |a|
  a.name = "Demo Team"
  a.plan = :growth
end
puts "  Account: #{account.name} (#{account.plan})"

# Create demo user
user = User.find_or_create_by!(email: "pm@feedbackmind.com") do |u|
  u.account = account
  u.name = "Jane PM"
  u.password = "password123!"
  u.role = :owner
end
puts "  User: #{user.email} / password123!"

# Create sources
sources_data = [
  { source_type: :intercom, active: true, config: { "webhook_secret" => "demo_secret" } },
  { source_type: :slack, active: true, config: { "signing_secret" => "demo_secret", "team_id" => "T12345" } },
  { source_type: :gmail, active: true, config: {} },
  { source_type: :jira, active: false, config: {} },
  { source_type: :csv, active: true, config: {} }
]

sources = sources_data.map do |data|
  Source.find_or_create_by!(account: account, source_type: data[:source_type]) do |s|
    s.active = data[:active]
    s.config = data[:config]
  end
end
puts "  Sources: #{sources.count} created"

# Create sample feedbacks
ActsAsTenant.with_tenant(account) do
  feedback_samples = [
    { content: "The onboarding flow is confusing. I had to watch a YouTube video to understand how to set up my first source.", sentiment: :negative, topics: ["onboarding", "ux"], author_name: "Sarah K.", author_email: "sarah@example.com" },
    { content: "Love the weekly synthesis feature! It saves me hours of manual analysis every Monday.", sentiment: :positive, topics: ["synthesis", "productivity"], author_name: "Mike R.", author_email: "mike@example.com" },
    { content: "The dashboard loads slowly when I have more than 500 feedbacks. Takes about 4 seconds.", sentiment: :negative, topics: ["performance", "dashboard"], author_name: "Alex T.", author_email: "alex@example.com" },
    { content: "Would be great to have a Slack integration so I can get notified when new themes are detected.", sentiment: :neutral, topics: ["feature-request", "integrations", "slack"], author_name: "Chris L.", author_email: "chris@example.com" },
    { content: "The AI chat feature is incredibly useful. I asked it about billing complaints and got a detailed summary with citations.", sentiment: :positive, topics: ["chat", "ai"], author_name: "Emma W.", author_email: "emma@example.com" },
    { content: "CSV import broke when my file had special characters in the author name column.", sentiment: :negative, topics: ["bugs", "csv-import"], author_name: "David P.", author_email: "david@example.com" },
    { content: "The sentiment analysis is quite accurate. It correctly identified sarcasm in a few tricky feedbacks.", sentiment: :positive, topics: ["ai", "sentiment"], author_name: "Lisa M.", author_email: "lisa@example.com" },
    { content: "I'd like to be able to tag feedbacks manually in addition to the AI-generated topics.", sentiment: :neutral, topics: ["feature-request", "tagging"], author_name: "Tom H.", author_email: "tom@example.com" },
    { content: "Our team switched from Productboard to FeedbackMind. The AI synthesis is leagues ahead.", sentiment: :positive, topics: ["comparison", "synthesis"], author_name: "Nina S.", author_email: "nina@example.com" },
    { content: "The API rate limits are too low for our integration. We're hitting 429 errors during peak hours.", sentiment: :negative, topics: ["api", "rate-limiting"], author_name: "James B.", author_email: "james@example.com" },
    { content: "Pricing is fair for what you get. The Growth plan has everything we need.", sentiment: :positive, topics: ["pricing"], author_name: "Rachel G.", author_email: "rachel@example.com" },
    { content: "The mobile experience needs work. Hard to read the dashboard on my phone.", sentiment: :negative, topics: ["mobile", "ux"], author_name: "Kevin F.", author_email: "kevin@example.com" },
    { content: "Export to PDF would be really helpful for our monthly stakeholder reports.", sentiment: :neutral, topics: ["feature-request", "export"], author_name: "Amy C.", author_email: "amy@example.com" },
    { content: "The command palette (Cmd+K) is super fast. Feels like using Linear.", sentiment: :positive, topics: ["ux", "command-palette"], author_name: "Ben D.", author_email: "ben@example.com" },
    { content: "We need better filtering options. Filtering by date range and source type at the same time doesn't work well.", sentiment: :negative, topics: ["bugs", "filtering"], author_name: "Olivia J.", author_email: "olivia@example.com" },
  ]

  active_sources = sources.select(&:active?)

  feedback_samples.each_with_index do |data, i|
    source = active_sources[i % active_sources.length]
    Feedback.find_or_create_by!(account: account, source: source, content: data[:content]) do |f|
      f.sentiment = data[:sentiment]
      f.topics = data[:topics]
      f.author_name = data[:author_name]
      f.author_email = data[:author_email]
      f.received_at = rand(14).days.ago
      f.processed_at = rand(13).days.ago
      f.metadata = {}
    end
  end
  puts "  Feedbacks: #{account.feedbacks.count} created"

  # Create a weekly synthesis
  WeeklySynthesis.find_or_create_by!(account: account, week_start: Date.current.beginning_of_week(:monday)) do |ws|
    ws.feedback_count = account.feedbacks.count
    ws.executive_summary = "Product health is stable. Users love the AI synthesis and chat features. Main pain points are onboarding complexity and dashboard performance. Mobile experience and export features are frequently requested."
    ws.top_themes = [
      { "title" => "Onboarding Complexity", "description" => "New users find the setup process confusing", "feedback_count" => 3, "urgency" => "high", "sample_quotes" => ["I had to watch a YouTube video to understand how to set up my first source"], "suggested_action" => "Add interactive setup wizard" },
      { "title" => "Dashboard Performance", "description" => "Slow load times with large datasets", "feedback_count" => 2, "urgency" => "high", "sample_quotes" => ["Takes about 4 seconds with 500+ feedbacks"], "suggested_action" => "Add pagination and lazy loading" },
      { "title" => "Feature Requests", "description" => "Users want more integrations and export options", "feedback_count" => 4, "urgency" => "medium", "sample_quotes" => ["Export to PDF would be really helpful"], "suggested_action" => "Prioritize Slack notification and PDF export" }
    ]
    ws.biggest_risk = { "theme" => "Onboarding Churn", "potential_impact" => "Estimated 15% of trial users drop off during setup" }
    ws.quick_wins = ["Add tooltips to source setup", "Implement CSV export for reports", "Add loading spinners to dashboard"]
    ws.sent_at = 1.day.ago
  end
  puts "  Weekly synthesis created"
end

puts ""
puts "Seed complete!"
puts "Login: pm@feedbackmind.com / password123!"
puts "URL: http://localhost:3500"
