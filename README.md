# FeedbackMind

AI-powered feedback intelligence platform for product teams. Centralize feedback from every channel, surface patterns with AI, and ship what users actually need.

## Overview

FeedbackMind connects to Slack, Gmail, Jira, Typeform, App Store reviews, and CSV imports. It analyzes customer feedback using GPT-4.1 embeddings and semantic search to surface themes, sentiment trends, and actionable insights — delivered as weekly AI syntheses and an interactive RAG chat.

## Tech Stack

- **Framework**: Ruby on Rails 8.1 (Ruby 3.3.8)
- **Database**: PostgreSQL 16 with pgvector for semantic search
- **Background Jobs**: Sidekiq 7 with Redis
- **AI**: OpenAI GPT-4.1 (synthesis, chat) + text-embedding-3-small (vector search)
- **Frontend**: Tailwind CSS v3, Hotwire (Turbo + Stimulus), esbuild
- **Auth**: Devise 5 with OmniAuth (Slack, Google, Jira, Typeform)
- **Billing**: Stripe Checkout (subscriptions)
- **Email**: Postmark
- **Deployment**: Kamal 2 on Hetzner Cloud
- **Proxy**: Thruster with automatic TLS

## Features

- **Multi-source ingestion** — Slack, Gmail, Jira, Typeform, App Store, CSV, REST API
- **Sentiment analysis** — Positive/neutral/negative classification per feedback
- **Semantic search** — pgvector HNSW index for cosine similarity across all feedback
- **Weekly AI synthesis** — GPT-4.1 generates theme analysis, risk identification, quick wins
- **RAG chat** — Ask questions about your feedback data with source citations
- **Pipeline board** — Kanban tracking from raw feedback to shipped features
- **Multi-tenancy** — acts_as_tenant with Account scoping
- **Team management** — Owner/member roles, invite flow, plan-based user limits
- **Stripe billing** — Checkout sessions for Growth and Scale plans
- **Webhook ingestion** — Receive real-time feedback via provider webhooks
- **Rate limiting** — rack-attack on auth, chat, API, and webhook endpoints

## Setup

### Prerequisites

- Ruby 3.3+
- PostgreSQL 16+ with pgvector extension
- Redis 7+
- Node.js 20+ with Yarn
- Docker (for deployment)

### Local Development

```bash
# Install dependencies
bundle install
yarn install

# Setup database
bin/rails db:create db:migrate db:seed

# Start all services
bin/dev
```

Visit `http://localhost:3500`

### Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

See `.env.example` for the full list of required and optional variables.

### OAuth Callback URLs

Configure these in each provider's developer dashboard:

| Provider | Callback URL |
|----------|-------------|
| Slack | `https://YOUR_HOST/auth/slack_openid/callback` |
| Google | `https://YOUR_HOST/auth/google_oauth2/callback` |
| Jira | `https://YOUR_HOST/sources/callback/jira` |
| Typeform | `https://YOUR_HOST/sources/callback/typeform` |

## Deployment

Deployed via Kamal 2:

```bash
kamal env push   # Push secrets to server
kamal deploy     # Build and deploy
kamal app logs   # View logs
```

## API

Bearer token authentication via `Authorization: Bearer fm_xxx` header. Token available in Settings.

## Testing

```bash
bundle exec rspec    # 83 specs
```

## License

Proprietary. All rights reserved.
