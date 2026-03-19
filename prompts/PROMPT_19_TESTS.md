# PROMPT 19 — Tests + Final Verification

Write request specs for all web controllers. Create factories. Full end-to-end verification.

## Task 1: Create spec/support/auth_helpers.rb
Helper to sign_in_user and set ActsAsTenant.current_tenant. Include Devise::Test::IntegrationHelpers.

## Task 2: Create/update factories
- spec/factories/accounts.rb (with plan: :growth, onboarding_completed: true)
- spec/factories/users.rb (with account association, role: :owner)
- spec/factories/feedbacks.rb (with content, external_id, sentiment, topics, source association)
- spec/factories/sources.rb (with source_type: :intercom, active: true)
- spec/factories/weekly_syntheses.rb (with themes JSONB, summary)

## Task 3: Write request specs for all web controllers

### spec/requests/dashboard_spec.rb
- GET /dashboard returns 200
- Shows real feedback count
- Respects period parameter
- Redirects to onboarding if not completed
- Redirects to sign_in if not authenticated

### spec/requests/feedbacks_spec.rb
- GET /feedbacks returns 200
- Filters by sentiment
- Filters by source_type
- GET /feedbacks/:id shows detail
- Tenant isolation (can't see other account's feedbacks)

### spec/requests/syntheses_spec.rb
- GET /syntheses returns 200
- POST /syntheses enqueues WeeklySynthesisJob

### spec/requests/sources_spec.rb
- GET /sources returns 200
- POST /sources creates source
- DELETE /sources/:id destroys source

### spec/requests/chat_spec.rb
- POST /chat with growth plan works
- POST /chat with starter plan is rejected (plan gate)

### spec/requests/settings_spec.rb
- GET /settings returns 200
- PATCH /settings updates account
- POST /settings/regenerate_token generates new token

### spec/requests/pages_spec.rb
- GET / (root) works without authentication

Similar specs for pipeline, loop_tracker, onboarding.

## Task 4: Run all tests
```bash
bundle exec rspec --format documentation
```
ALL must pass.

## Task 5: Full end-to-end manual test
```bash
rails db:reset && rails db:seed
rails tailwindcss:build
rails server
```
Visit every page, test every interaction. Fix any remaining issues.
