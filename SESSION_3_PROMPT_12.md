# PROMPT 12 — Layout, Routes, CSS, Helper

## Context
Session 3 frontend build. All 38 files are pre-built in `session3_files/`. This prompt copies the foundational files: layout, routes, CSS, and helper.

## Instructions

Run these commands exactly:

```bash
# 1. Create directory structure
mkdir -p app/views/layouts
mkdir -p app/views/shared
mkdir -p app/views/pages
mkdir -p app/views/dashboard
mkdir -p app/views/feedbacks
mkdir -p app/views/syntheses
mkdir -p app/views/sources
mkdir -p app/views/pipeline
mkdir -p app/views/loop_tracker
mkdir -p app/views/settings
mkdir -p app/views/devise/sessions
mkdir -p app/views/devise/registrations
mkdir -p app/javascript/controllers

# 2. Copy layout files
cp session3_files/views/layouts/application.html.erb app/views/layouts/application.html.erb
cp session3_files/views/layouts/_sidebar.html.erb app/views/layouts/_sidebar.html.erb
cp session3_files/views/layouts/_topbar.html.erb app/views/layouts/_topbar.html.erb

# 3. Copy shared partials
cp session3_files/views/shared/_command_palette.html.erb app/views/shared/_command_palette.html.erb
cp session3_files/views/shared/_chat_panel.html.erb app/views/shared/_chat_panel.html.erb

# 4. Copy routes
cp session3_files/routes.rb config/routes.rb

# 5. Copy custom CSS
cp session3_files/assets/stylesheets/application.css app/assets/stylesheets/application.css

# 6. Copy helper
cp session3_files/helpers/application_helper.rb app/helpers/application_helper.rb

# 7. Copy landing page
cp session3_files/views/pages/home.html.erb app/views/pages/home.html.erb
```

After running, verify:
```bash
ls -la app/views/layouts/
ls -la app/views/shared/
ls -la app/helpers/application_helper.rb
cat config/routes.rb | head -20
```
