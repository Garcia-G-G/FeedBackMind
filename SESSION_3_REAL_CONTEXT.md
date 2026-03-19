# FEEDBACKMIND — SESSION 3 MASTER CONTEXT (Give this to Claude Code Max FIRST)

## Project State
FeedbackMind is a Rails 7.2 SaaS app. Sessions 1-2 built the full backend (models, API, webhooks, jobs, services). Session 3 builds the frontend and makes everything REAL and functional.

## What Already Works (Backend)
- 6 models: Account, User, Feedback, Source, WeeklySynthesis, ChatMessage
- 9 migrations with pgvector, all indexes
- API v1: accounts, sources, feedbacks, chat_messages, syntheses, billing
- Webhooks: Intercom, Slack, Typeform, Jira, Gmail, Stripe
- Jobs: FeedbackIngestJob, FeedbackEmbedJob, WeeklySynthesisJob
- Services: Openai::Client, Synthesis::RagChat, Synthesis::WeeklyBuilder, Feedbacks::CsvImporter, Feedbacks::Classifier, Feedbacks::Embedder, Billing::CreateCheckout, Billing::HandleWebhookEvent
- Devise auth + acts_as_tenant multi-tenancy
- Sidekiq + sidekiq-cron scheduling

## What Needs to Be Built Now
Pre-built files exist in `session3_files/` directory. The prompts that follow will:
1. Copy and integrate all frontend files (layout, views, controllers, Stimulus JS)
2. Create seed data for development
3. Add OAuth flows for source connections (Intercom, Slack, etc.)
4. Fix the chat controller plan gate bug
5. Wire up real data in dashboard (remove mock fallbacks)
6. Create Turbo Frames/Streams for real-time updates
7. Add proper error handling and empty states
8. Configure environment properly

## Tech Stack
- Ruby on Rails 7.2, Ruby 3.3
- PostgreSQL + pgvector (HNSW index)
- Hotwire: Turbo Drive/Frames/Streams + Stimulus
- Tailwind CSS (via tailwindcss-rails gem)
- Sidekiq 7.3 + sidekiq-cron
- OpenAI GPT-4.1 + text-embedding-3-small
- Stripe billing
- Devise 5.0 auth
- Kamal 2 deployment

## Design System
- Light mode: bg-gray-50, white cards, indigo-500 accent
- Inter font via Google Fonts
- Rounded-xl cards, subtle shadows, clean whitespace
- Stimulus controllers for: command palette, chat panel, role switcher, period selector

## Key File Locations
- Models: app/models/
- API controllers: app/controllers/api/v1/
- Web controllers: app/controllers/ (to be added)
- Webhook controllers: app/controllers/webhooks/
- Services: app/services/
- Jobs: app/jobs/
- Pre-built frontend: session3_files/
- Migrations: db/migrate/
- Prompts: app/prompts/

## 10 Implementation Rules
1. Always use acts_as_tenant scoping — never query without tenant
2. Use Turbo Frames for partial page updates
3. Use Turbo Streams for real-time broadcast
4. Stimulus controllers for client-side interactivity only
5. All OpenAI calls go through Openai::Client service
6. Background jobs for anything taking > 500ms
7. Plan limits enforced at model AND controller level
8. Strong params on every controller
9. Proper error handling with user-friendly messages
10. No inline styles — Tailwind utility classes only
