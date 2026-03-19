# PROMPT 18 — Stripe Billing UI + Plan Management

Wire up Settings with real Stripe Checkout and Customer Portal.

## Task 1: Create web BillingController

- create_checkout: calls Billing::CreateCheckout with plan param, redirects to Stripe Checkout URL
- portal: calls Billing::CreatePortalSession, redirects to Stripe Portal URL

## Task 2: Routes
```ruby
post "billing/checkout", to: "billing#create_checkout", as: :billing_checkout
get "billing/portal", to: "billing#portal", as: :billing_portal
```

## Task 3: Update Settings View — Billing Section

Show:
- Current plan badge + price
- Usage bars (feedbacks used / limit, sources used / limit)
- Upgrade buttons for higher plans (post to billing_checkout_path)
- "Manage Billing" link to billing_portal_path (if has stripe_customer_id)
- Handle success/cancelled params from Stripe redirect

## Task 4: API Token Management in Settings

Show:
- Masked API token display
- "Copy to clipboard" button (navigator.clipboard.writeText)
- "Regenerate" button with turbo_confirm dialog
- Curl example for API usage

Add mask_api_token helper to ApplicationHelper.

## Task 5: Add regenerate_token action to SettingsController
Post to settings_regenerate_token_path, calls current_account.regenerate_api_token!, redirects with notice.

Add route:
```ruby
resource :settings, only: [:show, :update], controller: "settings" do
  post :regenerate_token, on: :collection
end
```
