# PROMPT 20 — Environment Setup + Deploy Config

Configure everything needed to run the app in development and prepare for production deployment.

## Task 1: Create .env file for development

Create `.env` with all required variables. For local dev, use test/placeholder keys:

```env
# ── Database ──
DATABASE_URL=postgresql://localhost:5432/feedbackmind_development

# ── Redis (Sidekiq) ──
REDIS_URL=redis://localhost:6379/0

# ── OpenAI ──
OPENAI_API_KEY=sk-your-real-openai-key-here

# ── Stripe ──
STRIPE_SECRET_KEY=sk_test_your_stripe_test_key
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_test_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
STRIPE_PRICE_STARTER=price_your_starter_price_id
STRIPE_PRICE_GROWTH=price_your_growth_price_id
STRIPE_PRICE_SCALE=price_your_scale_price_id

# ── OAuth: Slack ──
SLACK_CLIENT_ID=
SLACK_CLIENT_SECRET=

# ── OAuth: Google (Gmail) ──
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# ── OAuth: Intercom ──
INTERCOM_CLIENT_ID=
INTERCOM_CLIENT_SECRET=
INTERCOM_WEBHOOK_SECRET=

# ── OAuth: Jira ──
JIRA_CLIENT_ID=
JIRA_CLIENT_SECRET=

# ── OAuth: Typeform ──
TYPEFORM_CLIENT_ID=
TYPEFORM_CLIENT_SECRET=

# ── Email (Postmark) ──
POSTMARK_API_TOKEN=

# ── App ──
APP_HOST=localhost:3000
RAILS_ENV=development
SECRET_KEY_BASE=generate_with_rails_secret
```

## Task 2: Add dotenv gem

Add to Gemfile (development/test group):
```ruby
group :development, :test do
  gem "dotenv-rails", "~> 3.1"
end
```

Run `bundle install`.

## Task 3: Update credentials references

Search the codebase for `Rails.application.credentials` calls and make them fall back to ENV vars:

```ruby
# In initializers, use pattern:
ENV["OPENAI_API_KEY"] || Rails.application.credentials.dig(:openai, :api_key)
```

Update these files:
- `app/services/openai/client.rb` — use ENV["OPENAI_API_KEY"]
- `config/initializers/stripe.rb` — use ENV["STRIPE_SECRET_KEY"]
- Webhook controllers — use ENV vars for webhook secrets

## Task 4: Create Procfile for local development

Create `Procfile.dev`:
```
web: bin/rails server -p 3000
css: bin/rails tailwindcss:watch
worker: bundle exec sidekiq
```

Create `bin/dev` script:
```bash
#!/usr/bin/env bash
if ! gem list foreman -i --silent; then
  echo "Installing foreman..."
  gem install foreman
fi
exec foreman start -f Procfile.dev "$@"
```

Make it executable: `chmod +x bin/dev`

## Task 5: Update Kamal deploy config

Update `config/deploy.yml` for Hetzner deployment:
```yaml
service: feedbackmind
image: feedbackmind/app

servers:
  web:
    hosts:
      - YOUR_HETZNER_IP
    labels:
      traefik.http.routers.feedbackmind.rule: Host(`app.feedbackmind.com`)
      traefik.http.routers.feedbackmind.tls.certresolver: letsencrypt
  worker:
    hosts:
      - YOUR_HETZNER_IP
    cmd: bundle exec sidekiq

registry:
  server: ghcr.io
  username: YOUR_GITHUB_USERNAME
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    RAILS_ENV: production
    RAILS_LOG_TO_STDOUT: true
    RAILS_SERVE_STATIC_FILES: true
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - REDIS_URL
    - OPENAI_API_KEY
    - STRIPE_SECRET_KEY
    - STRIPE_WEBHOOK_SECRET
    - SECRET_KEY_BASE

accessories:
  db:
    image: postgres:16
    host: YOUR_HETZNER_IP
    port: "127.0.0.1:5432:5432"
    env:
      clear:
        POSTGRES_DB: feedbackmind_production
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data

  redis:
    image: redis:7
    host: YOUR_HETZNER_IP
    port: "127.0.0.1:6379:6379"
    directories:
      - data:/data

traefik:
  options:
    publish:
      - "443:443"
    volume:
      - "/letsencrypt:/letsencrypt"
  args:
    entryPoints.websecure.address: ":443"
    certificatesResolvers.letsencrypt.acme.email: "garcia@feedbackmind.com"
    certificatesResolvers.letsencrypt.acme.storage: "/letsencrypt/acme.json"
    certificatesResolvers.letsencrypt.acme.httpchallenge: true
    certificatesResolvers.letsencrypt.acme.httpchallenge.entrypoint: web
```

## Task 6: Create Dockerfile

```dockerfile
FROM ruby:3.3-slim

RUN apt-get update -qq && apt-get install -y \
  build-essential libpq-dev nodejs npm git curl \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

COPY . .

RUN SECRET_KEY_BASE=dummy rails assets:precompile
RUN SECRET_KEY_BASE=dummy rails tailwindcss:build

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

## Task 7: Add .gitignore entries
```
.env
.env.local
.env.production
node_modules/
/tmp/*
/log/*
/storage/*
```

## Verify
1. `bin/dev` starts web server + Sidekiq + Tailwind watcher
2. App loads at http://localhost:3000
3. All ENV vars are read properly
4. No credentials errors
