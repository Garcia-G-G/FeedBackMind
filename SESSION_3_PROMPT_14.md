# PROMPT 14 — Views (All Pages)

## Context
Session 3 frontend build. Copy all ERB view files for every page.

## Instructions

Run these commands exactly:

```bash
# 1. Dashboard
cp session3_files/views/dashboard/index.html.erb app/views/dashboard/index.html.erb

# 2. Feedbacks
cp session3_files/views/feedbacks/index.html.erb app/views/feedbacks/index.html.erb
cp session3_files/views/feedbacks/show.html.erb app/views/feedbacks/show.html.erb

# 3. Syntheses
cp session3_files/views/syntheses/index.html.erb app/views/syntheses/index.html.erb
cp session3_files/views/syntheses/show.html.erb app/views/syntheses/show.html.erb
cp session3_files/views/syntheses/new.html.erb app/views/syntheses/new.html.erb

# 4. Sources
cp session3_files/views/sources/index.html.erb app/views/sources/index.html.erb
cp session3_files/views/sources/show.html.erb app/views/sources/show.html.erb
cp session3_files/views/sources/new.html.erb app/views/sources/new.html.erb

# 5. Pipeline
cp session3_files/views/pipeline/show.html.erb app/views/pipeline/show.html.erb

# 6. Loop Tracker
cp session3_files/views/loop_tracker/show.html.erb app/views/loop_tracker/show.html.erb

# 7. Settings
cp session3_files/views/settings/show.html.erb app/views/settings/show.html.erb

# 8. Devise custom views
cp session3_files/views/devise/sessions/new.html.erb app/views/devise/sessions/new.html.erb
cp session3_files/views/devise/registrations/new.html.erb app/views/devise/registrations/new.html.erb
```

After running, verify:
```bash
find app/views -name "*.html.erb" -type f | wc -l
find app/views -name "*.html.erb" -type f | sort
```

Expected: ~18+ ERB files across all view directories.
