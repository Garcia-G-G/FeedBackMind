# PROMPT 12 — Install All Frontend Files

All frontend files are pre-built in `session3_files/`. Copy them into the Rails app structure. Do NOT modify the file contents — just copy them.

## Step 1: Create directories
```bash
mkdir -p app/views/{layouts,shared,dashboard,feedbacks,syntheses,sources,pipeline,loop_tracker,settings,pages}
mkdir -p app/views/devise/{sessions,registrations}
mkdir -p app/javascript/controllers
```

## Step 2: Copy all files

### Layout + partials
```bash
cp session3_files/views/layouts/application.html.erb app/views/layouts/application.html.erb
cp session3_files/views/layouts/_sidebar.html.erb app/views/layouts/_sidebar.html.erb
cp session3_files/views/layouts/_topbar.html.erb app/views/layouts/_topbar.html.erb
cp session3_files/views/shared/_command_palette.html.erb app/views/shared/_command_palette.html.erb
cp session3_files/views/shared/_chat_panel.html.erb app/views/shared/_chat_panel.html.erb
```

### Controllers (9 web controllers)
```bash
cp session3_files/controllers/application_controller.rb app/controllers/application_controller.rb
cp session3_files/controllers/dashboard_controller.rb app/controllers/dashboard_controller.rb
cp session3_files/controllers/feedbacks_controller.rb app/controllers/feedbacks_controller.rb
cp session3_files/controllers/syntheses_controller.rb app/controllers/syntheses_controller.rb
cp session3_files/controllers/sources_controller.rb app/controllers/sources_controller.rb
cp session3_files/controllers/pipeline_controller.rb app/controllers/pipeline_controller.rb
cp session3_files/controllers/loop_tracker_controller.rb app/controllers/loop_tracker_controller.rb
cp session3_files/controllers/settings_controller.rb app/controllers/settings_controller.rb
cp session3_files/controllers/chat_controller.rb app/controllers/chat_controller.rb
```

### Views (20 ERB files)
```bash
cp session3_files/views/dashboard/index.html.erb app/views/dashboard/index.html.erb
cp session3_files/views/feedbacks/index.html.erb app/views/feedbacks/index.html.erb
cp session3_files/views/feedbacks/show.html.erb app/views/feedbacks/show.html.erb
cp session3_files/views/syntheses/index.html.erb app/views/syntheses/index.html.erb
cp session3_files/views/syntheses/show.html.erb app/views/syntheses/show.html.erb
cp session3_files/views/syntheses/new.html.erb app/views/syntheses/new.html.erb
cp session3_files/views/sources/index.html.erb app/views/sources/index.html.erb
cp session3_files/views/sources/show.html.erb app/views/sources/show.html.erb
cp session3_files/views/sources/new.html.erb app/views/sources/new.html.erb
cp session3_files/views/pipeline/show.html.erb app/views/pipeline/show.html.erb
cp session3_files/views/loop_tracker/show.html.erb app/views/loop_tracker/show.html.erb
cp session3_files/views/settings/show.html.erb app/views/settings/show.html.erb
cp session3_files/views/pages/home.html.erb app/views/pages/home.html.erb
cp session3_files/views/devise/sessions/new.html.erb app/views/devise/sessions/new.html.erb
cp session3_files/views/devise/registrations/new.html.erb app/views/devise/registrations/new.html.erb
```

### Helper
```bash
cp session3_files/helpers/application_helper.rb app/helpers/application_helper.rb
```

### Routes
```bash
cp session3_files/routes.rb config/routes.rb
```

### CSS
```bash
cp session3_files/assets/stylesheets/application.css app/assets/stylesheets/application.css
```

### Stimulus controllers (6 JS files)
```bash
cp session3_files/javascript/controllers/command_palette_controller.js app/javascript/controllers/command_palette_controller.js
cp session3_files/javascript/controllers/chat_panel_controller.js app/javascript/controllers/chat_panel_controller.js
cp session3_files/javascript/controllers/role_switcher_controller.js app/javascript/controllers/role_switcher_controller.js
cp session3_files/javascript/controllers/period_selector_controller.js app/javascript/controllers/period_selector_controller.js
cp session3_files/javascript/controllers/dismissible_controller.js app/javascript/controllers/dismissible_controller.js
cp session3_files/javascript/controllers/sidebar_controller.js app/javascript/controllers/sidebar_controller.js
```

## Step 3: Register Stimulus controllers

Check `app/javascript/controllers/index.js`. If it uses `eagerLoadControllersFrom` then Stimulus will auto-discover controllers by filename. If it uses manual registration, add imports for all 6 new controllers.

## Step 4: Verify
```bash
find app/views -name "*.html.erb" | wc -l
find app/controllers -name "*.rb" -not -path "*/api/*" -not -path "*/webhooks/*" -not -path "*/concerns/*" | wc -l
ls app/javascript/controllers/*.js | wc -l
rails routes 2>&1 | head -50
```

Expected: ~20+ views, 10+ web controllers, 8+ JS controllers, all routes defined.
