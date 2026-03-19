# PROMPT 16 — Verification + Fixes

## Context
Session 3 frontend build complete. All files copied. Now verify everything works.

## Verification Steps

Run each command and check for errors:

```bash
# 1. Check routes compile
rails routes 2>&1 | head -40

# 2. Check all controllers can be loaded
rails runner "Rails.application.eager_load!; puts 'All files loaded successfully'"

# 3. Check Zeitwerk autoloading
rails runner "puts Rails.autoloaders.main.class; Rails.application.eager_load!; puts 'Zeitwerk OK'"

# 4. Verify controller count
rails runner "puts ApplicationController.descendants.select { |c| c.name && !c.name.start_with?('Devise') }.map(&:name).sort"

# 5. Verify views exist for all routes
rails routes 2>&1 | grep -E "GET.*dashboard|GET.*feedbacks|GET.*syntheses|GET.*sources|GET.*pipeline|GET.*loop_tracker|GET.*settings"

# 6. Run existing specs (should still pass)
bundle exec rspec --format progress 2>&1

# 7. Check Tailwind compiles
rails tailwindcss:build 2>&1 | tail -5

# 8. Start server briefly to check for boot errors
timeout 10 rails server -p 3001 2>&1 || true
```

## Expected Results
- Routes: should show all web routes (dashboard, feedbacks, syntheses, sources, pipeline, loop_tracker, settings, chat) plus existing API and webhook routes
- Eager load: should print "All files loaded successfully" with no errors
- Controllers: should list DashboardController, FeedbacksController, SynthesesController, SourcesController, PipelineController, LoopTrackerController, SettingsController, ChatController, PagesController plus all API controllers
- Specs: 36 examples, 0 failures (existing specs unchanged)
- Server: should boot without errors on port 3001

## Common Issues and Fixes

1. If `new_synthesis_path` undefined in topbar: the routes use `syntheses_path` for index and `new_synthesis_path` for new. Check routes output.

2. If helper method `sidebar_link` not found: make sure application_helper.rb was copied correctly.

3. If Stimulus controllers not loading: check that app/javascript/controllers/index.js imports them, or that eagerLoadControllersFrom is set up.

4. If Devise views not rendering: make sure `config.scoped_views = true` is set in config/initializers/devise.rb, OR the views are in app/views/devise/ (not app/views/users/).

5. If `current_account` is nil: make sure the set_tenant before_action runs after authenticate_user! in ApplicationController.

6. If CSS not applying: run `rails tailwindcss:build` and check that application.css is included in the layout.
