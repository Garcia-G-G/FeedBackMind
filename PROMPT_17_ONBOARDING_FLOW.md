# PROMPT 17 — User Onboarding Flow

Create a guided onboarding experience for new users. After signup, guide them through connecting their first source and importing feedback.

## Task 1: Add onboarding state to Account

Create a migration:
```bash
rails generate migration AddOnboardingToAccounts onboarding_completed:boolean onboarding_step:integer
```

Migration should default `onboarding_completed: false` and `onboarding_step: 0`.

## Task 2: Create OnboardingController

```ruby
class OnboardingController < ApplicationController
  before_action :redirect_if_completed

  def show
    @step = current_account.onboarding_step || 0
  end

  def update
    step = params[:step].to_i

    case step
    when 1
      # Update account name
      current_account.update!(name: params[:account_name]) if params[:account_name].present?
    when 2
      # Source connected (handled by OAuth callback)
    when 3
      # Complete onboarding
      current_account.update!(onboarding_completed: true, onboarding_step: 3)
      redirect_to dashboard_path, notice: "Welcome to FeedbackMind! Your dashboard is ready."
      return
    end

    current_account.update!(onboarding_step: step)
    redirect_to onboarding_path
  end

  def skip
    current_account.update!(onboarding_completed: true)
    redirect_to dashboard_path
  end

  private

  def redirect_if_completed
    redirect_to dashboard_path if current_account.onboarding_completed?
  end
end
```

## Task 3: Create Onboarding View

Create `app/views/onboarding/show.html.erb` — A clean, step-by-step wizard:

**Step 0: Welcome**
- "Welcome to FeedbackMind, Garcia!"
- "Let's set up your workspace in under 2 minutes"
- Team name input field
- "Continue" button

**Step 1: Connect Your First Source**
- Show grid of source types with connect buttons
- Each button triggers OAuth or shows instructions
- "I connected at least one source" or "Skip for now"
- Show a green checkmark next to connected sources (check current_account.sources.active)

**Step 2: See Your Dashboard**
- "You're all set!"
- Show a preview/summary: "X sources connected, ready to analyze feedback"
- "Go to Dashboard" button
- Option to import a CSV as first data

Design: Centered card (max-w-lg mx-auto), progress bar at top showing steps, clean minimal design matching the app aesthetic. No sidebar during onboarding.

## Task 4: Create Onboarding Layout

Create `app/views/layouts/onboarding.html.erb` — A minimal layout WITHOUT the sidebar, just centered content with the FeedbackMind logo.

The OnboardingController should use this layout:
```ruby
layout "onboarding"
```

## Task 5: Add routes
```ruby
resource :onboarding, only: [:show, :update], controller: "onboarding" do
  post :skip, on: :collection
end
```

## Task 6: Redirect new users to onboarding

In DashboardController, add:
```ruby
before_action :check_onboarding

private

def check_onboarding
  unless current_account.onboarding_completed?
    redirect_to onboarding_path
  end
end
```

## Task 7: Update Devise Registration

After user signs up (in the Devise registrations controller or via a callback), set onboarding_step to 0 so they hit the onboarding flow.

The existing custom registrations controller already creates the Account. Just make sure it sets:
```ruby
account = Account.create!(name: "My Team", subdomain: subdomain, plan: :starter, onboarding_completed: false, onboarding_step: 0)
```

## Verify
1. Sign up as a new user → redirected to onboarding
2. Enter team name → step 1
3. Connect a source (or skip) → step 2
4. Click "Go to Dashboard" → onboarding marked complete
5. Subsequent logins go directly to dashboard
