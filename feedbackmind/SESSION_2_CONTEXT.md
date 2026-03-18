# FeedbackMind — Session 2 Context Update

## What was built in Session 1

The full Rails scaffolding is complete and verified:

- **8 migrations** all ran successfully: pgvector extension → accounts → users → sources → feedbacks → HNSW embedding index → weekly_syntheses → chat_messages
- **6 models** with associations, validations, enums, scopes, and tenant isolation via acts_as_tenant
- **5 Sidekiq jobs**: FeedbackIngestJob, FeedbackEmbedJob, WeeklySynthesisJob, AppStoreScraperJob, MonthlyFeedbackCountResetJob
- **5 service objects**: Openai::Client, Feedback::Classifier, Feedback::Embedder, Synthesis::WeeklyBuilder, Synthesis::RagChat
- **3 prompt templates**: weekly_synthesis.txt, rag_chat.txt, feedback_classifier.txt
- **Initializers**: sidekiq.rb, sidekiq_cron.rb, openai.rb, stripe.rb, devise
- **6 factories + 2 model specs** (18 examples, 0 failures)
- Procfile + Procfile.dev configured

## What we're building in Session 2

Backend API layer + webhook receivers. No frontend views yet. Everything is JSON API.

### Goals

1. **Routes** — RESTful API namespace (`/api/v1/`) + webhook namespace (`/webhooks/`) + Devise auth routes + Sidekiq web dashboard mount
2. **Authentication** — API token auth for programmatic access + Devise session auth for web
3. **Webhook receivers** — Endpoints that receive POST payloads from Intercom, Slack, Typeform, Jira, and Stripe, verify signatures where applicable, normalize the payload, and enqueue FeedbackIngestJob
4. **API controllers** — CRUD for sources, read-only for feedbacks (with filtering), chat endpoint that calls RagChat service, synthesis listing
5. **Stripe billing** — Webhook handler for subscription lifecycle events (created, updated, deleted, payment_failed), customer portal session creation, checkout session creation
6. **CSV import** — Endpoint that accepts a CSV file upload, parses it, and enqueues each row as a FeedbackIngestJob
7. **Request authentication & rate limiting** — API key auth via account tokens, webhook signature verification per source type

### API Design Principles

- All API endpoints return JSON
- Namespace: `/api/v1/` for client-facing API
- Namespace: `/webhooks/` for incoming webhook receivers (no auth — verified by signature)
- Use `before_action` for tenant scoping and authentication
- Standard HTTP status codes: 200, 201, 204, 401, 403, 404, 422, 429
- Error responses follow: `{ "error": "message", "code": "error_code" }`
- Pagination via `page` and `per_page` params (default 25, max 100)

### Webhook Signature Verification

Each source type has its own signature verification method:
- **Intercom**: HMAC-SHA256 of request body with webhook secret, compared to `X-Hub-Signature` header
- **Slack**: HMAC-SHA256 with `v0:timestamp:body`, compared to `X-Slack-Signature` header
- **Stripe**: `Stripe::Webhook.construct_event` with endpoint secret
- **Typeform**: HMAC-SHA256 with form secret, compared to `Typeform-Signature` header
- **Jira**: HMAC-SHA256 or IP whitelist verification

### Expected File Structure After Session 2

```
app/controllers/
├── concerns/
│   ├── api_authenticatable.rb      # API token authentication
│   └── paginatable.rb             # Shared pagination logic
├── api/
│   └── v1/
│       ├── base_controller.rb     # API base (JSON format, auth, tenant scoping)
│       ├── feedbacks_controller.rb # index (filtered), show
│       ├── sources_controller.rb   # CRUD for sources
│       ├── chat_controller.rb      # create message → RagChat → return answer
│       ├── syntheses_controller.rb # index, show (weekly syntheses)
│       └── accounts_controller.rb  # show current account, update
├── webhooks/
│   ├── base_controller.rb         # Webhook base (skip CSRF, raw body parsing)
│   ├── intercom_controller.rb     # POST /webhooks/intercom
│   ├── slack_controller.rb        # POST /webhooks/slack
│   ├── typeform_controller.rb     # POST /webhooks/typeform
│   ├── jira_controller.rb         # POST /webhooks/jira
│   ├── stripe_controller.rb       # POST /webhooks/stripe
│   └── gmail_controller.rb        # POST /webhooks/gmail (via Cloudflare email routing or Google Pub/Sub)
├── billing/
│   ├── checkout_controller.rb     # Create Stripe Checkout session
│   └── portal_controller.rb       # Create Stripe Customer Portal session
└── application_controller.rb

app/services/
├── webhooks/                       # NEW — payload normalizers per source
│   ├── intercom_normalizer.rb
│   ├── slack_normalizer.rb
│   ├── typeform_normalizer.rb
│   ├── jira_normalizer.rb
│   └── gmail_normalizer.rb
├── billing/                        # NEW — Stripe operations
│   ├── create_checkout.rb
│   ├── create_portal_session.rb
│   └── handle_webhook_event.rb
└── feedback/
    ├── csv_importer.rb            # NEW — parse CSV and enqueue jobs
    ├── classifier.rb
    └── embedder.rb
```
