# PROMPT 36 — Full Audit + Fix: Jira, Typeform, Stripe

## CONTEXT
FeedbackMind is a Rails 8.0 app deployed via Kamal 2 to Hetzner (5.161.238.195.sslip.io).
Three features are BROKEN in production and have been broken for multiple deploys despite multiple fix attempts:

1. **Jira Connect button** — clicking "Connect Jira" does nothing or errors
2. **Typeform Connect button** — clicking "Connect Typeform" does nothing or errors
3. **Stripe plan upgrade** — clicking "Upgrade" in Settings does nothing

## PHASE 1: AUDIT (Do this FIRST, do NOT skip)

### 1A. Check the ACTUAL deployed code vs local code
```bash
# Check git status - are there uncommitted changes?
git status
git diff --stat

# Check if local changes match what's deployed
git log --oneline -5
```

### 1B. Test the Jira OAuth flow locally
```bash
# 1. Check if JIRA_CLIENT_ID is set
echo "JIRA_CLIENT_ID from .env: $(grep JIRA_CLIENT_ID .env | cut -d= -f2)"

# 2. Check the route exists
bin/rails routes | grep "connect_source\|jira_callback\|sources/connect\|sources/callback"

# 3. Check what URL the controller generates for Jira callback
bin/rails runner "
  # Simulate what production_base_url returns
  host = ENV.fetch('APP_HOST', '5.161.238.195.sslip.io')
  protocol = ENV.fetch('APP_PROTOCOL', 'https')
  puts 'production_base_url: #{protocol}://#{host}'
  puts 'jira_callback_url: #{protocol}://#{host}/sources/callback/jira'
  puts 'typeform_callback_url: #{protocol}://#{host}/sources/callback/typeform'
"

# 4. Check the controller file for any syntax errors
ruby -c app/controllers/source_connections_controller.rb
ruby -c app/controllers/settings_controller.rb
```

### 1C. Test Stripe configuration
```bash
# Check Stripe env vars
bin/rails runner "
  puts 'STRIPE_SECRET_KEY present: ' + ENV['STRIPE_SECRET_KEY'].present?.to_s
  puts 'STRIPE_SECRET_KEY starts with: ' + (ENV['STRIPE_SECRET_KEY'] || '')[0..6]
  puts 'STRIPE_STARTER_PRICE_ID: ' + ENV.fetch('STRIPE_STARTER_PRICE_ID', 'MISSING')
  puts 'STRIPE_GROWTH_PRICE_ID: ' + ENV.fetch('STRIPE_GROWTH_PRICE_ID', 'MISSING')
  puts 'STRIPE_SCALE_PRICE_ID: ' + ENV.fetch('STRIPE_SCALE_PRICE_ID', 'MISSING')
  puts 'Stripe.api_key set: ' + Stripe.api_key.present?.to_s
"

# Test if Stripe API key actually works
bin/rails runner "
  begin
    Stripe.api_key = ENV['STRIPE_SECRET_KEY']
    prices = Stripe::Price.list(limit: 3)
    puts 'Stripe API works! Found #{prices.data.length} prices:'
    prices.data.each { |p| puts '  #{p.id} - #{p.unit_amount} #{p.currency}' }
  rescue => e
    puts 'Stripe API ERROR: #{e.class} - #{e.message}'
  end
"
```

### 1D. Check the views for nested forms or Turbo issues
```bash
# Check if button_to forms in sources/new.html.erb could be nested inside other forms
grep -n "form_with\|form_for\|form_tag\|button_to\|</form>" app/views/sources/new.html.erb

# Check onboarding step 3
grep -n "form_with\|form_for\|form_tag\|button_to\|</form>" app/views/onboarding/_step_3.html.erb

# Check settings show for button_to Stripe
grep -n "form_with\|form_for\|form_tag\|button_to\|</form>\|change_plan\|turbo" app/views/settings/show.html.erb
```

### 1E. Check .kamal/secrets has real values (not placeholders)
```bash
# Verify secrets file has real values
grep -E "JIRA_CLIENT_ID|TYPEFORM_CLIENT_ID|STRIPE_SECRET_KEY|STRIPE_.*_PRICE_ID" .kamal/secrets
```

### 1F. Check production logs (if SSH access available)
```bash
# Try to get recent production logs
kamal app logs --since 10m 2>/dev/null | grep -E "\[OAuth\]|\[Stripe\]|Error|error|500" | tail -30
```

## PHASE 2: FIX (Based on audit findings)

After completing ALL audit steps above, fix the issues found. Here are the known problems and their fixes:

### Fix 1: Source Connections Controller — Callback URLs

The `jira_callback_sources_url` and `typeform_callback_sources_url` methods use `url_for()` which can generate wrong URLs in production (http://localhost:3000 instead of https://production-domain).

**Replace the old URL methods** in `app/controllers/source_connections_controller.rb`:

Delete these methods if they exist:
- `jira_callback_sources_url`
- `typeform_callback_sources_url`

Replace with explicit URL construction:
```ruby
private

def production_base_url
  host = ENV.fetch("APP_HOST", "5.161.238.195.sslip.io")
  protocol = ENV.fetch("APP_PROTOCOL", "https")
  "#{protocol}://#{host}"
end

def jira_callback_url
  "#{production_base_url}/sources/callback/jira"
end

def typeform_callback_url
  "#{production_base_url}/sources/callback/typeform"
end
```

Then update ALL references in the same file:
- In `jira_auth_url`: change `redirect_uri: jira_callback_sources_url` to `redirect_uri: jira_callback_url`
- In `typeform_auth_url`: change `redirect_uri: typeform_callback_sources_url` to `redirect_uri: typeform_callback_url`
- In `jira_callback` action: change `redirect_uri: jira_callback_sources_url` to `redirect_uri: jira_callback_url`
- In `typeform_callback` action: change `redirect_uri: typeform_callback_sources_url` to `redirect_uri: typeform_callback_url`

Add logging to the `create` action:
```ruby
def create
  provider = params[:provider]
  Rails.logger.info "[OAuth] Connect request for provider=#{provider}"
  session[:return_to_onboarding] = true if params[:return_to] == "onboarding"
  # ... rest of the method
end
```

And in the jira/typeform cases, log the auth URL before redirecting:
```ruby
when "jira"
  # ... blank check ...
  auth_url = jira_auth_url
  Rails.logger.info "[OAuth] Jira auth URL: #{auth_url}"
  redirect_to auth_url, allow_other_host: true
```

### Fix 2: Settings View — Stripe Button

The `button_to` for plan upgrades has `data: { turbo: false, turbo_confirm: "..." }`. This is a conflict: `turbo: false` disables Turbo, so `turbo_confirm` is ignored. This can cause the form to not submit in some browsers.

In `app/views/settings/show.html.erb`, find the button_to for plan changes and replace:

**FROM:**
```erb
<%= button_to ..., data: { turbo: false, turbo_confirm: "Change your plan to ..." }, ... %>
```

**TO:**
```erb
<%= button_to ..., form: { data: { turbo: "false" } }, ... %>
```

Remove `turbo_confirm` entirely. Put `data: { turbo: "false" }` on the `form:` option so it goes on the `<form>` tag, not the `<button>`.

### Fix 3: Settings Controller — Stripe Logging

In `app/controllers/settings_controller.rb`, add extensive logging to `change_plan`:

```ruby
def change_plan
  plan = params[:plan]
  Rails.logger.info "[Stripe] change_plan called with plan=#{plan}"

  # ... validation ...

  if ENV["STRIPE_SECRET_KEY"].present?
    Rails.logger.info "[Stripe] STRIPE_SECRET_KEY is present"
    price_id = case plan
               when "starter" then ENV["STRIPE_STARTER_PRICE_ID"]
               when "growth" then ENV["STRIPE_GROWTH_PRICE_ID"]
               when "scale" then ENV["STRIPE_SCALE_PRICE_ID"]
               end
    Rails.logger.info "[Stripe] Price ID for #{plan}: #{price_id.present? ? price_id : 'MISSING'}"

    if price_id.present?
      begin
        base_url = "https://#{ENV.fetch('APP_HOST', '5.161.238.195.sslip.io')}"
        session = Stripe::Checkout::Session.create(
          mode: "subscription",
          customer_email: current_user.email,
          line_items: [{ price: price_id, quantity: 1 }],
          success_url: "#{base_url}/settings?checkout=success&plan=#{plan}",
          cancel_url: "#{base_url}/settings?checkout=cancelled",
          metadata: { account_id: current_account.id, plan: plan }
        )
        Rails.logger.info "[Stripe] Checkout session created: #{session.url}"
        redirect_to session.url, allow_other_host: true
        return
      rescue Stripe::StripeError => e
        Rails.logger.error "[Stripe] Checkout error: #{e.message}"
        redirect_to settings_path, alert: "Payment setup failed: #{e.message}"
        return
      rescue => e
        Rails.logger.error "[Stripe] Unexpected error: #{e.class} - #{e.message}"
        redirect_to settings_path, alert: "Payment error: #{e.message}"
        return
      end
    end
  else
    Rails.logger.warn "[Stripe] STRIPE_SECRET_KEY not set"
  end

  # Fallback
  current_account.update!(plan: plan)
  redirect_to settings_path, notice: "Plan changed to #{plan.titleize}."
end
```

### Fix 4: Ensure views use correct button_to syntax

In `app/views/sources/new.html.erb` and `app/views/onboarding/_step_3.html.erb`, verify that ALL Connect buttons for Jira and Typeform have:

```erb
<%= button_to "Connect Jira", connect_source_path(provider: "jira"),
    method: :post,
    data: { turbo: false },
    class: "..." %>
```

Key requirements:
- `data: { turbo: false }` — MUST be present, prevents Turbo from intercepting the cross-origin redirect
- `method: :post` — MUST be POST
- The button must NOT be nested inside another `<form>` tag

### Fix 5: Verify .kamal/secrets

Ensure `.kamal/secrets` contains these real values (NOT "placeholder"):
- JIRA_CLIENT_ID=uQ3itzm0FjzwjVpjWNqlj2SjVrUNy76w
- JIRA_CLIENT_SECRET=(real value from .env)
- TYPEFORM_CLIENT_ID=9tc9c1RP1H9uLkRyJe4Sewfzi4jMWkVT4hiS1qBaRRnA
- TYPEFORM_CLIENT_SECRET=(real value from .env)
- STRIPE_SECRET_KEY=sk_test_... (real value)
- STRIPE_STARTER_PRICE_ID=price_... (real value)
- STRIPE_GROWTH_PRICE_ID=price_... (real value)
- STRIPE_SCALE_PRICE_ID=price_... (real value)

Also add if missing:
```
APP_HOST=5.161.238.195.sslip.io
APP_PROTOCOL=https
```

## PHASE 3: VERIFY LOCALLY

```bash
# Verify controller has no syntax errors
ruby -c app/controllers/source_connections_controller.rb
ruby -c app/controllers/settings_controller.rb

# Verify views have no ERB syntax errors
bin/rails runner "ActionView::Template::Error rescue nil; puts 'Views OK'"

# Start the dev server and test the Jira redirect
bin/rails runner "
  require 'net/http'
  # Simulate what the controller does
  client_id = ENV.fetch('JIRA_CLIENT_ID', '')
  callback = 'https://5.161.238.195.sslip.io/sources/callback/jira'
  params = {
    audience: 'api.atlassian.com',
    client_id: client_id,
    scope: 'read:jira-work write:jira-work read:jira-user',
    redirect_uri: callback,
    state: 'test',
    response_type: 'code',
    prompt: 'consent'
  }
  url = 'https://auth.atlassian.com/authorize?' + URI.encode_www_form(params)
  puts 'Jira auth URL would be:'
  puts url
  puts ''
  puts 'Verify:'
  puts '  - client_id is NOT empty or placeholder: #{client_id}'
  puts '  - redirect_uri is https://5.161.238.195.sslip.io/sources/callback/jira'
"
```

## PHASE 4: COMMIT AND DEPLOY

```bash
# Stage all changes
git add app/controllers/source_connections_controller.rb
git add app/controllers/settings_controller.rb
git add app/views/settings/show.html.erb
git add app/views/sources/new.html.erb
git add app/views/onboarding/_step_3.html.erb
git add .kamal/secrets

# Commit
git commit -m "Fix Jira/Typeform OAuth callback URLs and Stripe checkout

- Replace url_for with explicit production_base_url for OAuth callbacks
- Fix button_to turbo/turbo_confirm conflict in settings view
- Add extensive logging for OAuth and Stripe flows
- Ensure .kamal/secrets has all real credentials"

# Push env and deploy
kamal env push
kamal deploy
```

## PHASE 5: POST-DEPLOY VERIFICATION

```bash
# Check production logs for our new logging
kamal app logs --since 5m | grep -E "\[OAuth\]|\[Stripe\]" | tail -20

# Test that the endpoints respond
curl -sk -o /dev/null -w "%{http_code}" https://5.161.238.195.sslip.io/up
```

## IMPORTANT NOTES

- You CAN create new files if needed (helpers, concerns, initializers, tests, etc.). Do whatever is necessary to make these 3 features work.
- Do NOT touch Devise, Sidekiq, or any other working features.
- The `authenticated :user do` block in routes.rb wraps all source connection routes — this is correct, do not change it.
- OmniAuth callbacks (Slack, Gmail) are at `/auth/:provider/callback` — these are OUTSIDE the authenticated block and work differently from Jira/Typeform.
- Jira and Typeform use a custom OAuth flow (not OmniAuth), handled by `source_connections#create` → redirect to provider → `source_connections#jira_callback` / `typeform_callback`.

## REDIRECT URIs TO CONFIGURE IN PROVIDER DASHBOARDS (Manual step, not code)

After deploy, the user needs to verify these redirect URIs are configured:
- **Jira** at developer.atlassian.com: `https://5.161.238.195.sslip.io/sources/callback/jira`
- **Typeform** at admin.typeform.com: `https://5.161.238.195.sslip.io/sources/callback/typeform`
- **Slack** at api.slack.com: `https://5.161.238.195.sslip.io/auth/slack_openid/callback`
- **Google** at console.cloud.google.com: `https://5.161.238.195.sslip.io/auth/google_oauth2/callback`
