# PROMPT 17 — User Onboarding Flow

Create a guided 3-step onboarding for new users.

## Task 1: Migration
```bash
rails generate migration AddOnboardingToAccounts onboarding_completed:boolean onboarding_step:integer
```
Default: onboarding_completed: false, onboarding_step: 0. Run migrate.

## Task 2: OnboardingController

- show: renders current step based on current_account.onboarding_step
- update: processes each step (0=team name, 1=connect source, 2=complete)
- skip: marks onboarding complete, redirects to dashboard
- before_action: redirect to dashboard if already completed

Use layout "onboarding" (minimal, no sidebar).

## Task 3: Create onboarding layout

app/views/layouts/onboarding.html.erb — Minimal: just logo centered, bg-gray-50, no sidebar/topbar.

## Task 4: Create onboarding view

app/views/onboarding/show.html.erb — Step wizard:

Step 0: "Welcome! Let's set up your workspace" — team name input, Continue button
Step 1: "Connect your first source" — grid of source type cards with connect buttons, shows green check for connected ones, "Skip for now" link
Step 2: "You're all set!" — summary of what's connected, "Go to Dashboard" button

Progress bar at top showing current step. Clean centered card design (max-w-lg mx-auto).

## Task 5: Routes
```ruby
resource :onboarding, only: [:show, :update], controller: "onboarding" do
  post :skip, on: :collection
end
```

## Task 6: Redirect new users

In DashboardController, add before_action :check_onboarding that redirects to onboarding_path unless current_account.onboarding_completed?

## Task 7: Update Devise Registration

Make sure the custom registrations controller sets onboarding_completed: false on new accounts.
