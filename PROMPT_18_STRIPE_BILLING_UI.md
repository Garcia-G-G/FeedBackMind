# PROMPT 18 — Stripe Billing UI + Plan Management

Wire up the Settings billing section with real Stripe Checkout and Portal.

## Task 1: Create BillingController (Web)

```ruby
class BillingController < ApplicationController
  def create_checkout
    plan = params[:plan]
    result = Billing::CreateCheckout.call(
      account: current_account,
      plan: plan,
      success_url: settings_url(billing: "success"),
      cancel_url: settings_url(billing: "cancelled")
    )

    if result[:url]
      redirect_to result[:url], allow_other_host: true
    else
      redirect_to settings_path, alert: "Could not create checkout session."
    end
  end

  def portal
    result = Billing::CreatePortalSession.call(
      account: current_account,
      return_url: settings_url
    )

    if result[:url]
      redirect_to result[:url], allow_other_host: true
    else
      redirect_to settings_path, alert: "Could not open billing portal."
    end
  end
end
```

## Task 2: Add billing routes
```ruby
post "billing/checkout", to: "billing#create_checkout", as: :billing_checkout
get  "billing/portal", to: "billing#portal", as: :billing_portal
```

## Task 3: Update Settings View — Billing Section

In `app/views/settings/show.html.erb`, the billing section should show:

### Current Plan
- Plan name badge (Starter/Growth/Scale)
- Monthly price
- Usage stats: feedbacks used this month / limit
- Sources used / limit

### Upgrade Options
For each plan above the current plan, show:
- Plan name, price, features
- "Upgrade" button that posts to `billing_checkout_path(plan: "growth")`

### Manage Subscription
If account has a stripe_customer_id:
- "Manage Billing" button linking to `billing_portal_path`
- Shows next billing date, payment method on file

### Usage Bars
Show visual progress bars:
```erb
<%% usage_pct = (current_account.feedbacks_count_this_month.to_f / current_account.feedback_limit * 100).round %>
<div class="h-2 bg-gray-100 rounded-full overflow-hidden">
  <div class="h-full rounded-full <%%= usage_pct > 90 ? 'bg-red-500' : 'bg-indigo-500' %>"
       style="width: <%%= [usage_pct, 100].min %>%"></div>
</div>
<p class="text-xs text-gray-400 mt-1">
  <%%= current_account.feedbacks_count_this_month %> / <%%= current_account.feedback_limit %> feedbacks this month
</p>
```

## Task 4: Handle Billing Success/Cancel

In settings, show flash based on params:
```erb
<%% if params[:billing] == "success" %>
  <div class="bg-emerald-50 border border-emerald-200 text-emerald-800 px-4 py-3 rounded-lg text-sm mb-4">
    Plan upgraded successfully! Your new features are now active.
  </div>
<%% elsif params[:billing] == "cancelled" %>
  <div class="bg-amber-50 border border-amber-200 text-amber-800 px-4 py-3 rounded-lg text-sm mb-4">
    Checkout was cancelled. No changes made to your plan.
  </div>
<%% end %>
```

## Task 5: API Token Management in Settings

The settings page should show:
- Current API token (partially masked: `fm_live_****...****abc`)
- "Regenerate Token" button (with confirmation dialog)
- "Copy to clipboard" button
- API usage example (curl command)

```erb
<div class="flex items-center gap-2">
  <code class="flex-1 bg-gray-50 px-3 py-2 rounded-lg text-sm font-mono text-gray-600 truncate">
    <%%= mask_api_token(current_account.api_token) %>
  </code>
  <button onclick="navigator.clipboard.writeText('<%%= current_account.api_token %>')"
    class="px-3 py-2 text-xs font-medium border rounded-lg hover:bg-gray-50">
    Copy
  </button>
  <%%= button_to "Regenerate", settings_regenerate_token_path, method: :post,
    data: { turbo_confirm: "Are you sure? This will invalidate the current token." },
    class: "px-3 py-2 text-xs font-medium text-red-600 border border-red-200 rounded-lg hover:bg-red-50" %>
</div>
```

Add to ApplicationHelper:
```ruby
def mask_api_token(token)
  return "No token generated" if token.blank?
  "#{token[0..7]}...#{token[-4..]}"
end
```

## Task 6: Add regenerate_token route
```ruby
resource :settings, only: [:show, :update], controller: "settings" do
  post :regenerate_token, on: :collection
end
```

And in SettingsController:
```ruby
def regenerate_token
  current_account.regenerate_api_token!
  redirect_to settings_path, notice: "API token regenerated. Update your integrations."
end
```

## Verify
1. Visit /settings → see current plan + usage
2. Click "Upgrade to Growth" → redirect to Stripe Checkout
3. After payment → redirect back with success message
4. Click "Manage Billing" → Stripe Customer Portal
5. Copy API token → works
6. Regenerate token → new token shown
