# FeedbackMind — Rails New Command

Run this to create the project (if starting fresh with Rails CLI):

```bash
rails new feedbackmind \
  --database=postgresql \
  --skip-test \
  --skip-jbuilder \
  --css=tailwind \
  --javascript=esbuild \
  --skip-action-mailbox
```

## Flags Explained

- `--database=postgresql` — PostgreSQL for pgvector support
- `--skip-test` — We use RSpec instead of Minitest
- `--skip-jbuilder` — Not needed, we return JSON directly
- `--css=tailwind` — Tailwind CSS via Rails asset pipeline
- `--javascript=esbuild` — Fast JS bundling with Hotwire/Stimulus
- `--skip-action-mailbox` — Not needed (we receive webhooks, not inbound email)

## Post-creation steps

1. Replace the generated Gemfile with the one in this project
2. Run `bundle install`
3. Run `rails db:create`
4. Run `rails db:migrate`
5. Run `rails generate devise:install`
6. Run `rails generate devise User`
7. Configure `config/initializers/devise.rb`

## Environment Requirements

- Ruby >= 3.1 (3.2+ recommended for YJIT)
- PostgreSQL >= 15 with pgvector extension installed
- Redis >= 6.0 (required by Sidekiq 7+)
- Node.js >= 18 (for esbuild)
