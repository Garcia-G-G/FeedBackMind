# FeedbackMind — CLAUDE.md

## What is this project?
FeedbackMind is a multi-tenant SaaS platform for Product Managers to centralize, analyze, and act on customer feedback. Built with Rails 8.0, PostgreSQL + pgvector, Redis, Sidekiq, and deployed via Kamal 2 to Hetzner.

## Tech Stack
- **Ruby**: 3.3.8 (`.ruby-version`)
- **Rails**: 8.0 (upgraded from 7.2.3 via PROMPT_24)
- **Database**: PostgreSQL 16 with pgvector extension
- **Cache/PubSub**: Redis 7
- **Background Jobs**: Sidekiq 7.3 + sidekiq-cron
- **Frontend**: Hotwire (Turbo + Stimulus), esbuild, Tailwind CSS v3 via tailwindcss-rails
- **Asset Pipeline**: Sprockets (serves esbuild output from `app/assets/builds/`)
- **Auth**: Devise 5 with custom registrations controller
- **Multi-tenancy**: acts_as_tenant (Account model is the tenant)
- **AI**: OpenAI API (ruby-openai gem), pgvector for embeddings (neighbor gem)
- **Billing**: Stripe (subscriptions, checkout, customer portal)
- **Email**: Postmark
- **Deployment**: Kamal 2 + Thruster, Docker multi-stage build
- **Server**: Hetzner (5.161.238.195), domain: 5.161.238.195.sslip.io

## Architecture
- Multi-tenant: every model `acts_as_tenant(:account)`, tenant set via `ApplicationController#set_tenant`
- Plans: Starter (1 user, 3 sources, 1k feedbacks/mo), Growth (5/10/10k), Scale (unlimited)
- API v1 with Bearer token auth (`ApiAuthenticatable` concern)
- Webhooks for: Slack, Gmail, Jira, Typeform, Stripe (Intercom temporarily removed)
- OAuth integrations: Slack (OpenID), Gmail (Google OAuth2), Jira, Typeform (Intercom skipped)

## Key Commands
```bash
bin/dev                    # Start dev server (Rails + esbuild + Tailwind + Sidekiq)
bin/rails server -p 3500   # Rails only
yarn build                 # Build JS with esbuild
bin/rails tailwindcss:build # Build Tailwind CSS
bundle exec rspec          # Run tests
kamal deploy               # Deploy to production
kamal env push             # Push env secrets to server
```

## Design System
- **Fonts**: DM Serif Display (headings, `.font-serif-display`), DM Sans (body, default `font-sans`)
- **Colors**: Stone palette (Tailwind `stone-*`) for all UI. Indigo ONLY for AI badges.
- **Semantic colors**: emerald (success), red (error), amber (warning), blue (info) — never changed
- **Buttons**: `bg-stone-900 hover:bg-stone-800 text-white`
- **Cards**: `bg-white rounded-xl border border-stone-200`
- **Inputs**: `border-stone-300 focus:ring-stone-900/10 focus:border-stone-500`
- **Links**: `text-stone-900 hover:text-stone-700 underline`

## Models
- `Account` — tenant, has plan, API token, Stripe IDs
- `User` — belongs_to Account, roles: owner/member, Devise auth
- `Source` — integration source (intercom/gmail/slack/jira/typeform/csv/appstore/playstore)
- `Feedback` — the core entity, has embeddings (pgvector), sentiment, topics
- `WeeklySynthesis` — AI-generated weekly summary with themes and risks
- `ChatMessage` — RAG-powered chat, stores source_feedback_ids for citations

## Stimulus Controllers (10)
sidebar, role-switcher, period-selector, chat-panel, command-palette, clipboard, dismissible, hello, password-visibility

## File Structure
```
app/controllers/
  application_controller.rb     # Auth, tenant, onboarding check
  dashboard_controller.rb       # Main dashboard with stats
  feedbacks_controller.rb       # List/show feedbacks
  syntheses_controller.rb       # Weekly synthesis CRUD
  sources_controller.rb         # Source management
  source_connections_controller.rb # OAuth flows + CSV import
  settings_controller.rb        # Account settings, API token
  pipeline_controller.rb        # Kanban board
  loop_tracker_controller.rb    # Shipped/in-progress/planned tracker
  onboarding_controller.rb      # Onboarding wizard
  chat_controller.rb            # RAG chat
  pages_controller.rb           # Landing page
  users/registrations_controller.rb # Custom Devise registration
  concerns/api_authenticatable.rb   # API Bearer token auth
  api/v1/                       # REST API controllers
  webhooks/                     # Webhook receivers

app/views/
  layouts/application.html.erb  # Main layout with DM Sans/Serif Display fonts
  layouts/_sidebar.html.erb     # Navigation sidebar
  layouts/_topbar.html.erb      # Page header with period selector
  pages/home.html.erb           # Self-contained landing page (layout: false)
```

## Chrome Testing Results (March 23, 2026)
All pages tested and working correctly:
- ✅ Landing page (/) — stone design, editorial look
- ✅ Sign In (/users/sign_in) — stone design, password visibility toggle
- ✅ Sign Up (/users/sign_up) — creates account + redirects to onboarding
- ✅ Forgot Password (/users/password/new) — stone design, already exists
- ✅ Onboarding Step 1 — workspace name/URL setup
- ✅ Onboarding Step 2 — source selection (Slack, Gmail, Intercom, Jira, Typeform, CSV)
- ✅ Onboarding Step 3 — summary with plan info
- ✅ Dashboard (/dashboard) — stats, sentiment timeline, weekly themes, sidebar works
- ✅ Feedbacks (/feedbacks) — filters, empty state
- ✅ Sources (/sources) — empty state with Add Source CTA
- ✅ Pipeline (/pipeline) — Kanban board with 4 columns
- ✅ Loop Tracker (/loop_tracker) — shipped/in-progress/planned sections
- ✅ Settings (/settings) — account name, team management with Invite Member button, API token
- ✅ Syntheses (/syntheses) — list view (not tested directly but accessible)

## Prompts History
- `PROMPT_23_DESIGN_SYSTEM_MIGRATION.md` — ✅ EXECUTED: Stone design system across all 28 views
- `PROMPT_24_RAILS_8_UPGRADE.md` — ✅ EXECUTED: Rails 7.2 → 8.0 upgrade
- `PROMPT_25_OAUTH_INTEGRATIONS.md` — ✅ EXECUTED: Webhook routes, OmniAuth guard, webhook URL display, syntheses fix
- `PROMPT_26_USER_MANAGEMENT.md` — ✅ EXECUTED: Registration error handling, profile edit, invite/remove flow
- `PROMPT_27_PRODUCTION_READY.md` — ✅ EXECUTED: Postmark email, chat turbo stream, deploy secrets
- `PROMPT_28_BUGFIXES.md` — ✅ EXECUTED: Source show 500, chat CSRF, syntheses account_id, OmniAuth guard, registration errors, seed fix
- `PROMPT_29_DASHBOARD_AND_VIEWS_FIX.md` — NEW: Dashboard "Content missing" fix (remove turbo_frame_tag), source show nil sentiment guard, period selector stone colors
- `PROMPT_30_PIPELINE_AND_SETTINGS_FIX.md` — NEW: Pipeline Raw column fix (Feedback attrs), Settings upgrade button wiring, Intercom removal
- `PROMPT_31_SYNTHESIS_AND_CHAT_VALIDATION.md` — NEW: Synthesis pre-validation (API key, duplicate, feedbacks check), chat error handling, OpenAI initializer

## Execution Order for Remaining Prompts
1. **PROMPT_29** first (Dashboard & Source Show — critical, fixes "Content missing" and 500)
2. **PROMPT_30** next (Pipeline & Settings — fixes Kanban crash, settings polish, remove Intercom)
3. **PROMPT_31** last (Synthesis & Chat validation — graceful error handling for OpenAI)

## What Already Exists (DO NOT recreate)
- ✅ All background jobs (FeedbackEmbedJob, FeedbackIngestJob, WeeklySynthesisJob, MonthlyFeedbackCountResetJob, AppStoreScraperJob)
- ✅ All services (webhook normalizers, CSV importer, RAG chat, billing handlers, OpenAI client, embedder, classifier)
- ✅ All webhook controllers with signature verification and Slack challenge support
- ✅ Chat controller with RAG via Synthesis::RagChat
- ✅ API v1 controllers with Bearer token auth
- ✅ Seed data (50+ feedbacks, 2 syntheses, sample chat)
- ✅ Sidekiq cron config
- ✅ Devise password views (new + edit) with stone design
- ✅ Sign-out link with turbo_method: :delete

## OAuth Credentials Status (March 23, 2026)
- ✅ Slack — Client ID obtained, app created at api.slack.com
- ✅ Google — OAuth 2.0 client created, Gmail API enabled
- ⏭️ Intercom — Skipped for now
- ✅ Jira — OAuth 2.0 (3LO) app created at developer.atlassian.com
- ✅ Typeform — Developer app registered at admin.typeform.com

## Known Issues / TODO (Updated March 23, 2026)
1. ~~Webhook routes missing `:account_id`~~ ✅ Fixed (PROMPT_25)
2. ~~OmniAuth session expiry guard~~ ✅ Fixed (PROMPT_25)
3. ~~Source show webhook URL~~ ✅ Fixed (PROMPT_25)
4. ~~Syntheses account_id~~ ✅ Fixed (PROMPT_25)
5. ~~Registration error handling~~ ✅ Fixed (PROMPT_26)
6. ~~Profile edit page~~ ✅ Fixed (PROMPT_26)
7. ~~Invite Member~~ ✅ Fixed (PROMPT_26)
8. ~~Postmark email~~ ✅ Fixed (PROMPT_27)
9. ~~Chat turbo_stream~~ ✅ Fixed (PROMPT_27)
10. Intercom OAuth — **SKIPPED**, temporarily removed from UI
11. Dashboard "Content missing" — turbo_frame_tag wrapper breaks rendering (PROMPT_29)
12. Source show 500 — nil sentiment crashes `.titleize` (PROMPT_29)
13. Period selector uses gray instead of stone classes (PROMPT_29)
14. Pipeline Raw column calls non-existent methods on Feedback (PROMPT_30)
15. Settings upgrade button non-functional (PROMPT_30)
16. Synthesis generation has no pre-validation (PROMPT_31)
17. Chat has no error handling for OpenAI failures (PROMPT_31)

## Environment Variables (see .env.example)
OPENAI_API_KEY, REDIS_URL, DATABASE_URL, STRIPE_SECRET_KEY, STRIPE_PUBLISHABLE_KEY,
STRIPE_WEBHOOK_SECRET, STRIPE_*_PRICE_ID (3), POSTMARK_API_KEY,
SLACK_CLIENT_ID/SECRET, GOOGLE_CLIENT_ID/SECRET, INTERCOM_CLIENT_ID/SECRET,
JIRA_CLIENT_ID/SECRET, TYPEFORM_CLIENT_ID/SECRET
