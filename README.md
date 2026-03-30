# FeedbackMind

AI-powered feedback intelligence platform for product teams. Centralize feedback from every channel, surface patterns with AI, and ship what users actually need.

## Overview

FeedbackMind connects to Slack, Gmail, Jira, Typeform, App Store reviews, NPS surveys, and CSV imports. It analyzes customer feedback using GPT-4.1 embeddings and semantic search to surface themes, sentiment trends, and actionable insights — delivered as weekly AI syntheses, priority scoring, and an interactive RAG chat.

## Tech Stack

- **Framework**: Ruby on Rails 8.1 (Ruby 3.3.8)
- **Database**: PostgreSQL 16 with pgvector for semantic search
- **Background Jobs**: Sidekiq 7 with Redis
- **AI**: OpenAI GPT-4.1 (synthesis, chat, priority scoring) + text-embedding-3-small (vector search)
- **Frontend**: Tailwind CSS v3, Hotwire (Turbo + Stimulus), esbuild
- **Auth**: Devise 5 with OmniAuth (Google OAuth login + source integrations)
- **Billing**: Stripe Checkout (subscriptions)
- **Email**: Resend (transactional + team invitations + status notifications)
- **Deployment**: Kamal 2 on Hetzner Cloud
- **Proxy**: Thruster with automatic TLS

## Features

### Core
- **Multi-source ingestion** — Slack, Gmail, Jira, Typeform, App Store, NPS, CSV, REST API, manual sync
- **Sentiment analysis** — Positive/neutral/negative classification per feedback
- **AI priority scoring** — GPT-4.1 scores urgency, business impact, frequency, severity (0-100)
- **Semantic search** — pgvector HNSW index for cosine similarity and duplicate detection
- **Weekly AI synthesis** — Theme analysis, risk identification, quick wins
- **RAG chat** — Ask questions about your feedback data with source citations
- **Smart reply** — AI-generated reply suggestions matching feedback language and tone
- **Pipeline board** — Kanban tracking from raw feedback to shipped features

### Feature Request Portal
- **Public voting board** — `/portal/:subdomain` — anyone can submit and vote
- **Public roadmap** — 3-column board (Planned / In Progress / Shipped)
- **Public changelog** — Timeline of product updates linked to shipped requests
- **Status notifications** — Voters notified via email when request status changes
- **Embeddable widgets** — Feedback submission + NPS survey widgets (vanilla JS, no deps)

### NPS Surveys
- **Embeddable NPS widget** — Score 0-10 + follow-up question
- **Analytics dashboard** — NPS score, promoter/passive/detractor breakdown, score distribution
- **CORS restrictions** — Configurable allowed origins per survey

### Customer Intelligence
- **Company segmentation** — Auto-groups feedback by email domain (B2B)
- **Segments** — Enterprise, Mid-Market, SMB, Startup, Free Trial, Churned
- **MRR tracking** — Revenue impact per company
- **Feedback tagging** — Manual tags with GIN index for fast filtering
- **CSV export** — Download feedbacks with all metadata
- **Saved filter views** — Preset + custom filter combinations

### Collaboration
- **Team invitations** — Email-based, token-secured, 7-day expiry
- **Google OAuth login** — Sign in / Sign up with Google
- **Email confirmation** — Devise confirmable with styled emails
- **Role-based access** — Owner / Admin / Member with authorization concern
- **Slack notifications** — Real-time alerts for new feedback and critical priority items
- **Onboarding checklist** — Guided 5-step setup on dashboard

### Platform
- **Multi-tenancy** — acts_as_tenant with Account scoping
- **Stripe billing** — Checkout sessions for Growth and Scale plans
- **Webhook ingestion** — Real-time feedback via provider webhooks
- **REST API v1** — Bearer token auth, CRUD for sources/feedbacks/chat
- **Rate limiting** — rack-attack on auth, chat, API, and webhook endpoints
- **Content Security Policy** — Report-only mode with strict defaults
- **Security** — Email confirmation, CORS restrictions, authorization, CSRF

## Plans

| | Starter | Growth | Scale |
|---|---|---|---|
| Price | $29/mo | $109/mo | $209/mo |
| Users | 1 | 5 | Unlimited |
| Sources | 3 | 10 | Unlimited |
| Feedbacks/mo | 1,000 | 10,000 | Unlimited |
| AI Chat | - | Yes | Yes |
| Portal | - | Yes | Yes |
| API | - | - | Yes |

## Setup

### Prerequisites

- Ruby 3.3+
- PostgreSQL 16+ with pgvector extension
- Redis 7+
- Node.js 20+ with Yarn
- Docker (for deployment)

### Local Development

```bash
bundle install
yarn install
bin/rails db:create db:migrate
bin/dev
```

Visit `http://localhost:3500`

### Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

Key variables: `OPENAI_API_KEY`, `RESEND_API_KEY`, `STRIPE_SECRET_KEY`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `SLACK_CLIENT_ID`, `SLACK_CLIENT_SECRET`

### OAuth Callback URLs

| Provider | Callback URL |
|----------|-------------|
| Google (login) | `https://YOUR_HOST/users/auth/google_oauth2/callback` |
| Slack (source) | `https://YOUR_HOST/auth/slack_openid/callback` |
| Gmail (source) | `https://YOUR_HOST/auth/google_gmail/callback` |
| Jira | `https://YOUR_HOST/sources/callback/jira` |
| Typeform | `https://YOUR_HOST/sources/callback/typeform` |

## Deployment

```bash
kamal env push   # Push secrets to server
kamal deploy     # Build and deploy
kamal app logs   # View logs
```

## Testing

```bash
bundle exec rspec    # 113 specs, 0 failures
```

## License

Proprietary. All rights reserved.
