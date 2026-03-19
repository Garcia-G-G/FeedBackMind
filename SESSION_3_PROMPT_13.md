# PROMPT 13 — Controllers

## Context
Session 3 frontend build. Copy all 9 web controllers. These are separate from the existing API controllers in app/controllers/api/.

## Important
The new `application_controller.rb` REPLACES the existing one. It adds tenant management and authentication. The existing API controllers in `app/controllers/api/` and `app/controllers/webhooks/` remain untouched.

## Instructions

Run these commands exactly:

```bash
# 1. Copy ApplicationController (replaces existing)
cp session3_files/controllers/application_controller.rb app/controllers/application_controller.rb

# 2. Copy all web controllers
cp session3_files/controllers/dashboard_controller.rb app/controllers/dashboard_controller.rb
cp session3_files/controllers/feedbacks_controller.rb app/controllers/feedbacks_controller.rb
cp session3_files/controllers/syntheses_controller.rb app/controllers/syntheses_controller.rb
cp session3_files/controllers/sources_controller.rb app/controllers/sources_controller.rb
cp session3_files/controllers/pipeline_controller.rb app/controllers/pipeline_controller.rb
cp session3_files/controllers/loop_tracker_controller.rb app/controllers/loop_tracker_controller.rb
cp session3_files/controllers/settings_controller.rb app/controllers/settings_controller.rb
cp session3_files/controllers/chat_controller.rb app/controllers/chat_controller.rb
```

After running, verify:
```bash
ls -la app/controllers/*.rb | wc -l
ls app/controllers/*.rb
```

Expected: 10 controllers in app/controllers/ (application + 9 feature controllers) plus the existing pages_controller.rb = 11 total. The api/ and webhooks/ subdirectories remain unchanged.

## IMPORTANT NOTE
If the existing `app/controllers/sources_controller.rb` conflicts with the web one (because the API already has one at `app/controllers/api/v1/sources_controller.rb`), there is NO conflict because they are in different namespaces. The web one is `SourcesController`, the API one is `Api::V1::SourcesController`.

Similarly for feedbacks: web `FeedbacksController` vs API `Api::V1::FeedbacksController`.
