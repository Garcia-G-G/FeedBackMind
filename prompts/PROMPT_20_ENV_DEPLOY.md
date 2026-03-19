# PROMPT 20 — Environment + Deploy

Configure environment variables, Procfile, Docker, and Kamal for deployment.

## Task 1: Add dotenv gem
```ruby
# Gemfile, development/test group:
gem "dotenv-rails", "~> 3.1"
```
Bundle install.

## Task 2: Create .env with all variables
DATABASE_URL, REDIS_URL, OPENAI_API_KEY, all Stripe keys + price IDs, all OAuth client IDs/secrets (Slack, Google, Intercom, Jira, Typeform), POSTMARK_API_TOKEN, APP_HOST, SECRET_KEY_BASE.

## Task 3: Update services to use ENV vars
Search for Rails.application.credentials and add ENV fallbacks:
- Openai::Client → ENV["OPENAI_API_KEY"]
- Stripe config → ENV["STRIPE_SECRET_KEY"]
- Webhook secrets → ENV vars

## Task 4: Create Procfile.dev
```
web: bin/rails server -p 3000
css: bin/rails tailwindcss:watch
worker: bundle exec sidekiq
```

## Task 5: Create bin/dev script
Installs foreman if needed, runs Procfile.dev. chmod +x.

## Task 6: Dockerfile for production
Ruby 3.3-slim base, install deps, bundle, precompile assets + tailwind, expose 3000.

## Task 7: Kamal config (config/deploy.yml)
Configure for Hetzner with web + worker services, PostgreSQL + Redis accessories, Traefik with Let's Encrypt SSL.

## Task 8: .gitignore
Add .env, .env.local, .env.production, node_modules, tmp, log, storage.

## Verify
`bin/dev` starts everything. App loads at localhost:3000. No credentials errors.
