# FeedbackMind — Project Context for Claude Code Max

You are building **FeedbackMind**, a SaaS application that connects all feedback sources for a software product (Intercom, Gmail, App Store reviews, Typeform, Jira tickets, Slack) and uses OpenAI's GPT-4.1 to automatically synthesize them into actionable insights for Product Managers.

## The Problem

A PM today has feedback scattered across 10+ different tools and spends 30-40% of their week manually collecting and reading feedback. FeedbackMind ingests everything, vectorizes it, and every Monday sends a digest with the top 5 themes of the week, real user quotes, and a draft PRD ready to use. It also has a RAG chat where the PM can ask things like "what features did users who churned this month request?" and the system responds with real quotes and sources.

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Backend + Frontend | Ruby on Rails 7.2 | Hotwire (Turbo + Stimulus), server-rendered with sprinkles of interactivity |
| Database | PostgreSQL + `pgvector` extension | Relational data + vector embeddings for semantic search via cosine similarity |
| Vector Integration | `neighbor` gem (~> 0.4) | ActiveRecord integration for pgvector — handles vector columns, HNSW indexing, and nearest-neighbor queries natively |
| Background Jobs | Sidekiq (~> 7.3) + Redis | Async processing: ingestion, embedding generation, weekly synthesis, scraping |
| Scheduled Jobs | sidekiq-cron (~> 2.0) | Cron-like scheduling for weekly synthesis (Mon 8am UTC), app store scraping (every 6h), monthly counter reset (1st of month) |
| AI — Synthesis & Chat | OpenAI `gpt-4.1` | Weekly feedback synthesis, RAG chat with full history, PRD generation. Chosen over GPT-5.x for price/quality: superior instruction following, 1M token context, structured JSON output, much lower cost for high-volume batch requests |
| AI — Embeddings | OpenAI `text-embedding-3-small` | Vectorize each feedback on receipt. 1536 dimensions, extremely cheap (~$0.0002 per 1M tokens) |
| AI — Classification | OpenAI `gpt-4.1-mini` | Real-time lightweight tasks: classify sentiment (positive/neutral/negative) and generate topic tags per individual feedback |
| Authentication | Devise (~> 5.0) | User auth with Turbo compatibility (`data-turbo-confirm`, `data-turbo-method`) |
| Multi-tenancy | acts_as_tenant (~> 1.0) | Row-level tenant isolation via `account_id` on every tenant-scoped model |
| Billing | Stripe (~> 12.0) | Multi-tenant subscription billing with 3 plans |
| Email | ActionMailer + Postmark | Weekly digest emails, transactional notifications |
| Deployment | Kamal 2 → Hetzner CX22 | Docker-based zero-downtime deployment (2 vCPU, 4GB RAM, €5/mo) |
| CDN/Proxy | Cloudflare | DNS, HTTP proxy, webhook ingestion endpoint |
| CSS | Tailwind CSS | Utility-first styling |

## Database Schema

### Account
```
id, name (string, required), subdomain (string, unique, required),
stripe_customer_id (string), stripe_subscription_id (string),
plan (enum: starter=0/growth=1/scale=2, default: starter),
feedback_count_this_month (integer, default: 0), timestamps
```

### User (Devise-managed)
```
id, account_id (FK, required), email (string, unique, required),
encrypted_password, reset_password_token, reset_password_sent_at,
remember_created_at, sign_in_count, current_sign_in_at, last_sign_in_at,
current_sign_in_ip, last_sign_in_ip, name (string),
role (enum: owner=0/member=1, default: owner), timestamps
```

### Source
```
id, account_id (FK, required),
source_type (enum: intercom=0/gmail=1/appstore=2/playstore=3/typeform=4/jira=5/slack=6/csv=7, required),
config (jsonb, default: {}), active (boolean, default: false),
last_synced_at (datetime), timestamps
```

### Feedback
```
id, account_id (FK, required), source_id (FK, required),
external_id (string, unique per source — deduplication key),
content (text, required), author_email (string), author_name (string),
sentiment (enum: positive=0/neutral=1/negative=2),
topics (string array, default: []),
embedding (vector(1536) — pgvector, HNSW index with vector_cosine_ops),
metadata (jsonb, default: {}),
received_at (datetime), processed_at (datetime), timestamps
```

### WeeklySynthesis
```
id, account_id (FK, required), week_start (date, required, unique per account),
feedback_count (integer), top_themes (jsonb array of theme objects),
executive_summary (text), biggest_risk (jsonb: {theme, potential_impact}),
quick_wins (string array), sent_at (datetime), timestamps
```

### ChatMessage
```
id, account_id (FK, required), user_id (FK, required),
role (enum: user=0/assistant=1, required),
content (text, required),
source_feedback_ids (integer array — IDs of feedbacks used as RAG context),
timestamps
```

## Key Indexes

- `accounts.subdomain` — unique
- `accounts.stripe_customer_id` — unique partial (WHERE NOT NULL)
- `users.email` — unique
- `feedbacks(source_id, external_id)` — unique partial (WHERE external_id IS NOT NULL) — deduplication
- `feedbacks.embedding` — HNSW with `vector_cosine_ops` (NOT IVFFlat — HNSW is 15x faster and works on empty tables)
- `feedbacks.topics` — GIN index for array containment queries
- `feedbacks.processed_at` — partial index WHERE NULL (fast unprocessed lookup)
- `weekly_syntheses(account_id, week_start)` — unique

## Model Relationships & Tenancy

```
Account has_many: users, sources, feedbacks, weekly_syntheses, chat_messages
User belongs_to: account | has_many: chat_messages
Source belongs_to: account | has_many: feedbacks
Feedback belongs_to: account, source | has_neighbors :embedding (neighbor gem)
WeeklySynthesis belongs_to: account
ChatMessage belongs_to: account, user
```

All models except Account use `acts_as_tenant(:account)` for automatic tenant scoping.

## Sidekiq Jobs

| Job | Queue | Schedule | Purpose |
|-----|-------|----------|---------|
| `FeedbackIngestJob` | default | On-demand | Normalize raw feedback from any source, deduplicate via `external_id`, save to DB |
| `FeedbackEmbedJob` | default | After each feedback creation (via `after_create_commit`) | Call `text-embedding-3-small` for vector, call `gpt-4.1-mini` for sentiment + topics, update record |
| `WeeklySynthesisJob` | critical | Every Monday 8am UTC | For each active account: collect 7-day feedback, cluster by topic, send to `gpt-4.1` for synthesis, save result, email digest |
| `AppStoreScraperJob` | low | Every 6 hours | Scrape new App Store / Play Store reviews for accounts with active app store sources |
| `MonthlyFeedbackCountResetJob` | critical | 1st of each month midnight UTC | Reset `feedback_count_this_month` to 0 on all accounts |

## OpenAI Integration Patterns

### Embedding Generation
- Model: `text-embedding-3-small`
- Input: `feedback.content.truncate(8000)`
- Output: 1536-dimension float array → stored in `feedback.embedding` column
- Used by: `FeedbackEmbedJob`, `Synthesis::RagChat` (for question embedding)

### Sentiment + Topic Classification
- Model: `gpt-4.1-mini`
- Input: feedback text (truncated to 4000 chars)
- Output: JSON `{ "sentiment": "positive|neutral|negative", "topics": ["tag1", "tag2"] }`
- Response format: `{ type: "json_object" }` for guaranteed valid JSON
- Temperature: 0.1 (deterministic)
- Used by: `FeedbackEmbedJob`

### Weekly Synthesis
- Model: `gpt-4.1`
- Input: clustered feedback grouped by topic similarity
- Output: JSON with `top_themes`, `executive_summary`, `biggest_risk`, `quick_wins`
- Response format: `{ type: "json_object" }`
- Temperature: 0.3
- Prompt template: `app/prompts/weekly_synthesis.txt` with `{{feedback_count}}`, `{{week_start}}`, `{{week_end}}` placeholders
- Used by: `WeeklySynthesisJob`, `Synthesis::WeeklyBuilder`

### RAG Chat
- Model: `gpt-4.1`
- Flow: embed question → pgvector nearest neighbors (HNSW, cosine, top 20) → build context string → GPT-4.1 answers with citations
- Temperature: 0.4
- Prompt template: `app/prompts/rag_chat.txt` with `{{account_name}}` placeholder
- Used by: `Synthesis::RagChat`

## Stripe Plans & Limits

| Plan | Price | Users | Sources | Feedbacks/mo | Chat | PRD |
|------|-------|-------|---------|-------------|------|-----|
| Starter | $49/mo | 1 | 3 | 500 | No | No |
| Growth | $149/mo | 5 | 10 | 2,000 | Yes | No |
| Scale | $399/mo | ∞ | ∞ | ∞ | Yes | Yes |

Enforcement: `Account#feedback_limit_reached?` checks `feedback_count_this_month >= plan_limit`. When limit is hit, `FeedbackIngestJob` rejects with a log warning. The Scale plan has `Float::INFINITY` limits (never blocked).

## Service Layer Architecture

```
app/services/
├── openai/
│   └── client.rb          # Wrapper around ruby-openai gem (embed, chat_json, chat methods)
├── feedback/
│   ├── classifier.rb      # Sentiment + topic classification via gpt-4.1-mini
│   └── embedder.rb        # Vector embedding generation via text-embedding-3-small
└── synthesis/
    ├── weekly_builder.rb   # Weekly synthesis orchestration (cluster → prompt → GPT-4.1 → parse)
    └── rag_chat.rb         # RAG pipeline (embed question → pgvector search → GPT-4.1 answer)
```

## Prompt Templates

Stored as `.txt` files in `app/prompts/` with `{{placeholder}}` syntax for variable interpolation:
- `weekly_synthesis.txt` — System prompt for the weekly synthesis (senior PM persona)
- `rag_chat.txt` — System prompt for the RAG chat assistant
- `feedback_classifier.txt` — System prompt for sentiment/topic classification

## File Structure Convention

```
feedbackmind/
├── app/
│   ├── models/           # ActiveRecord models with validations, enums, scopes
│   ├── jobs/             # Sidekiq job classes
│   ├── services/         # Service objects (openai/, feedback/, synthesis/)
│   ├── prompts/          # OpenAI prompt templates (.txt)
│   ├── mailers/          # ActionMailer classes
│   ├── controllers/      # Rails controllers
│   ├── views/            # ERB templates
│   └── javascript/       # Stimulus controllers
├── config/
│   ├── initializers/     # sidekiq.rb, openai.rb, stripe.rb, sidekiq_cron.rb
│   └── environments/     # development.rb, production.rb, test.rb
├── db/
│   └── migrate/          # Migrations in chronological order
├── spec/
│   ├── models/           # Model specs
│   ├── jobs/             # Job specs
│   ├── services/         # Service specs
│   └── factories/        # FactoryBot factories
└── Procfile / Procfile.dev
```

## Key Implementation Rules

1. **Always use `acts_as_tenant`** — Every query on tenant-scoped models must be scoped to the current account. Use `ActsAsTenant.with_tenant(account) { ... }` in jobs.
2. **HNSW over IVFFlat** — The embedding index uses HNSW (`using: :hnsw, opclass: :vector_cosine_ops`). HNSW is 15x faster for queries and can be created on empty tables.
3. **`neighbor` gem for vector search** — Use `has_neighbors :embedding` in the Feedback model and `nearest_neighbors(:embedding, vector, distance: "cosine")` for semantic search.
4. **JSON response format** — All OpenAI calls that expect structured output must use `response_format: { type: "json_object" }`.
5. **Deduplication** — Feedback deduplication is via `external_id` scoped to `source_id` (unique composite index).
6. **Error isolation in batch jobs** — `WeeklySynthesisJob` and `AppStoreScraperJob` rescue per-account/per-source errors and continue processing the rest. One failure should never block all accounts.
7. **Feedback count enforcement** — Check `account.feedback_limit_reached?` before creating any new feedback. Reject gracefully, don't raise.
8. **Prompt templates** — Load from `app/prompts/*.txt` using `File.read(Rails.root.join("app/prompts/..."))` with `.gsub("{{var}}", value)` interpolation.
9. **Devise + Turbo** — Use `data-turbo-confirm` and `data-turbo-method` instead of the old `data-confirm` and `data-method`.
10. **Sidekiq queues** — Three priority levels: `critical` (synthesis, resets), `default` (ingestion, embedding), `low` (scraping).

## Competitive Differentiators (for context, not code)

- $49/mo vs $499/mo competitors (Zeda.io, Dovetail, Productboard)
- Native Spanish support — first tool built for LATAM product teams
- Feedback × revenue cross-analysis (connect client's Stripe in Scale plan)
- Full-history RAG chat with real quotes, sources, and dates

---

**Use this context for ALL prompts in this session. Every file you create must be consistent with this architecture.**
