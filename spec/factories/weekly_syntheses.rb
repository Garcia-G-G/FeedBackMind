FactoryBot.define do
  factory :weekly_synthesis do
    account
    week_start { Date.current.beginning_of_week(:monday) }
    feedback_count { 25 }
    executive_summary { "Product health is stable with growing feature requests around integrations." }
    top_themes { [{ "title" => "Integration Issues", "description" => "Users want more integrations", "feedback_count" => 8, "urgency" => "high", "sample_quotes" => ["Need Slack integration"], "suggested_action" => "Prioritize Slack integration" }] }
    biggest_risk { { "theme" => "Churn risk", "potential_impact" => "15% of users mentioned leaving" } }
    quick_wins { ["Fix onboarding flow", "Add CSV export"] }
  end
end
