# SESSION 3 CONTEXT — Frontend Build

## What Was Built (Sessions 1-2)
- Full Rails 7.2 backend: 6 models, 9 migrations, Sidekiq jobs, OpenAI services
- API v1 namespace with controllers, webhook receivers, Stripe billing
- 36 passing specs, Devise auth, acts_as_tenant multi-tenancy
- All backend is working. Session 3 is FRONTEND ONLY.

## What We're Building Now
Full Hotwire + Tailwind frontend matching the approved Prototype B Enhanced design.
Design principles: Clean light mode, Inter font, Notion/Linear-inspired, whitespace-rich.

## Key Differentiators (features no competitor has)
1. Command Palette (⌘K) — Linear-style instant search/navigation
2. AI Impact Score + MRR at Risk per theme
3. Sentiment Timeline — daily sentiment evolution chart
4. Feedback Pipeline — Kanban: Raw → Insights → Actions → Shipped
5. Closed-Loop Tracker — shows which feedbacks led to shipped features
6. Role-Based Views (PM/Eng/Exec) — adapts dashboard per role

## Tech Stack for Frontend
- Rails 7.2 views with ERB
- Hotwire: Turbo Drive, Turbo Frames, Turbo Streams
- Stimulus.js for interactive components
- Tailwind CSS (via tailwindcss-rails gem, already installed)
- Custom CSS for specific components (command palette, chat panel)
- Inter font via Google Fonts CDN

## File Organization
All new files are pre-built in `session3_files/` — prompts only use `cp` and `mkdir`.

## Design Tokens (Tailwind extended)
- Background: bg-gray-50 (#FAFAFA)
- Surface: bg-white
- Accent: indigo-500/600 (#6366F1)
- Positive: emerald-500
- Negative: red-500
- Neutral: amber-500
- Text: gray-900, gray-500, gray-400
- Radius: rounded-xl (cards), rounded-lg (buttons), rounded-md (inputs)
- Font: Inter, system fallback

## Routes to Add (Web namespace, separate from API)
```
root "dashboard#index"  # Change from pages#home
resources :feedbacks, only: [:index, :show]
resources :syntheses, only: [:index, :show]
resources :sources, only: [:index, :show, :new, :create, :destroy]
resource :pipeline, only: [:show], controller: "pipeline"
resource :loop_tracker, only: [:show], controller: "loop_tracker"
resource :settings, only: [:show, :update], controller: "settings"
post "/chat", to: "chat#create"
```

## Authentication
All web routes require `authenticate_user!` via Devise.
Dashboard is the post-login landing page.
Pages#home remains as the marketing landing page for non-logged-in users.
