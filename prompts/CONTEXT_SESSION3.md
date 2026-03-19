# FEEDBACKMIND — SESSION 3 MASTER CONTEXT

## Project State
FeedbackMind is a Rails 7.2 SaaS. Sessions 1-2 built the full backend. Session 3 (Prompt 12) installed the frontend: layout, 9 web controllers, 20+ views, 6 Stimulus controllers, routes. Everything compiles but uses hardcoded fallback data. Now we make it REAL.

## What Already Exists
- 6 models: Account, User, Feedback, Source, WeeklySynthesis, ChatMessage
- 9 migrations with pgvector + HNSW index
- API v1: accounts, sources, feedbacks, chat_messages, syntheses, billing
- Webhooks: Intercom, Slack, Typeform, Jira, Gmail, Stripe (with signature verification)
- Jobs: FeedbackIngestJob, FeedbackEmbedJob, WeeklySynthesisJob, MonthlyFeedbackCountResetJob
- Services: Openai::Client, Synthesis::RagChat, Synthesis::WeeklyBuilder, Feedbacks::CsvImporter, Feedbacks::Classifier, Feedbacks::Embedder, Billing::CreateCheckout, Billing::HandleWebhookEvent
- Frontend: Dashboard, Feedbacks, Syntheses, Sources, Pipeline, LoopTracker, Settings views
- Stimulus: CommandPalette, ChatPanel, RoleSwitcher, PeriodSelector, Dismissible, Sidebar controllers
- Auth: Devise + acts_as_tenant multi-tenancy
- Sidekiq + sidekiq-cron scheduling

## Tech Stack
Ruby on Rails 7.2, Ruby 3.3, PostgreSQL + pgvector, Hotwire (Turbo + Stimulus), Tailwind CSS, Sidekiq 7.3, OpenAI GPT-4.1 + text-embedding-3-small, Stripe, Devise 5.0, Kamal 2

## Key Rules
1. Always scope queries through current_account (acts_as_tenant)
2. Use Turbo Frames for partial updates, Turbo Streams for real-time
3. All OpenAI calls go through Openai::Client service
4. Background jobs for anything > 500ms
5. Plan limits enforced at model AND controller level
6. No inline styles — Tailwind only
