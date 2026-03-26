# PROMPT 37 — Fix Stripe Checkout + Onboarding Polish

## GOAL
Two things need to work:

1. **Stripe Checkout** — When user selects a paid plan (Growth or Scale) in BOTH onboarding Step 1 AND Settings, redirect to Stripe Checkout page where they enter credit card info (test mode). Starter plan should be free (no Stripe needed).

2. **Onboarding Step 2 left panel** — The preview card on the left side looks empty/broken. Show useful info there (plan selected, workspace preview with actual data).

3. **Jira/Typeform dashboard config info** — After the Connect buttons work (they now redirect correctly to the provider), show the user clear error info when the OAuth callback fails due to provider-side configuration.

## PART 1: STRIPE CHECKOUT

### Problem
Currently `onboarding_controller.rb#select_plan` just does `current_account.update!(plan: plan)` without any Stripe integration. And `settings_controller.rb#change_plan` HAS Stripe code but falls through to the direct plan change fallback. The user wants to see the actual Stripe Checkout page with card fields.

### Step 1: Verify Stripe is working
```bash
bin/rails runner "
  require 'stripe'
  Stripe.api_key = ENV['STRIPE_SECRET_KEY']
  puts 'API Key present: ' + Stripe.api_key.present?.to_s
  puts 'API Key prefix: ' + (Stripe.api_key || '')[0..6]

  # Test creating a checkout session
  begin
    session = Stripe::Checkout::Session.create(
      mode: 'subscription',
      customer_email: 'test@example.com',
      line_items: [{ price: ENV['STRIPE_GROWTH_PRICE_ID'], quantity: 1 }],
      success_url: 'https://5.161.238.195.sslip.io/settings?checkout=success',
      cancel_url: 'https://5.161.238.195.sslip.io/settings?checkout=cancelled'
    )
    puts 'SUCCESS! Checkout URL: ' + session.url
  rescue Stripe::InvalidRequestError => e
    puts 'Stripe Error: ' + e.message
    puts 'This likely means the price ID is invalid or Stripe API key is wrong'
  rescue => e
    puts 'Error: ' + e.class.to_s + ' - ' + e.message
  end
"
```

If the above fails with "No such price" — the price IDs in .env and .kamal/secrets are wrong. You need to:
1. Go to Stripe Dashboard → Products → Create Product for each plan
2. Get the real price IDs
3. Update .env and .kamal/secrets with the correct price IDs

If it fails with "Invalid API Key" — the STRIPE_SECRET_KEY is wrong.

### Step 2: Add Stripe to Onboarding Step 1

Modify `app/controllers/onboarding_controller.rb` — the `select_plan` method:

For paid plans (growth, scale), create a Stripe Checkout session and redirect. For starter (free), just save and continue. After successful payment, Stripe redirects back to onboarding with checkout=success, and we advance to step 2.

```ruby
def select_plan
  plan = params.dig(:account, :plan)
  unless plan.present? && %w[starter growth scale].include?(plan)
    @step = 1
    flash.now[:alert] = "Please select a plan to continue."
    render :show, status: :unprocessable_entity
    return
  end

  # Free plan — no payment needed
  if plan == "starter"
    current_account.update!(plan: plan)
    current_user.update!(onboarding_step: 2)
    redirect_to onboarding_path
    return
  end

  # Paid plan — redirect to Stripe Checkout
  if ENV["STRIPE_SECRET_KEY"].present?
    price_id = case plan
               when "growth" then ENV["STRIPE_GROWTH_PRICE_ID"]
               when "scale" then ENV["STRIPE_SCALE_PRICE_ID"]
               end

    if price_id.present?
      begin
        base_url = "https://#{ENV.fetch('APP_HOST', '5.161.238.195.sslip.io')}"
        checkout_session = Stripe::Checkout::Session.create(
          mode: "subscription",
          customer_email: current_user.email,
          line_items: [{ price: price_id, quantity: 1 }],
          success_url: "#{base_url}/onboarding?checkout=success&plan=#{plan}",
          cancel_url: "#{base_url}/onboarding?checkout=cancelled",
          metadata: { account_id: current_account.id, plan: plan }
        )
        redirect_to checkout_session.url, allow_other_host: true
        return
      rescue Stripe::StripeError => e
        Rails.logger.error("[Stripe] Onboarding checkout error: #{e.message}")
        flash.now[:alert] = "Payment setup failed: #{e.message}"
        @step = 1
        render :show, status: :unprocessable_entity
        return
      rescue => e
        Rails.logger.error("[Stripe] Onboarding unexpected error: #{e.class} - #{e.message}")
      end
    end
  end

  # Fallback if Stripe not configured — just save plan and continue
  Rails.logger.warn "[Stripe] Falling back to direct plan change (Stripe not configured or price ID missing)"
  current_account.update!(plan: plan)
  current_user.update!(onboarding_step: 2)
  redirect_to onboarding_path
end
```

### Step 3: Handle Stripe checkout return in onboarding

In the `show` action, handle the checkout success/cancel params:

```ruby
def show
  # Handle Stripe checkout return
  if params[:checkout] == "success" && params[:plan].present?
    plan = params[:plan]
    if %w[growth scale].include?(plan)
      current_account.update!(plan: plan)
      current_user.update!(onboarding_step: 2)
      redirect_to onboarding_path
      return
    end
  elsif params[:checkout] == "cancelled"
    flash.now[:alert] = "Payment was cancelled. You can select a different plan or try again."
  end

  @step = current_step
  @selected_plan = current_account.plan if @step == 1
end
```

### Step 4: Ensure Settings change_plan works the same way

The `settings_controller.rb#change_plan` already has Stripe code. Make sure it matches the same pattern — the key issue is that it must NOT fall through to the direct plan change if Stripe IS configured but the checkout creation fails. If Stripe fails, show the error to the user instead of silently changing the plan.

### Step 5: Add Stripe Checkout CSS classes

The `button_to` in settings for plan changes should have `form: { data: { turbo: "false" } }` on the form (NOT `data: { turbo: false }` on the button). This ensures the form submits as a regular HTML form that can follow cross-domain redirects to checkout.stripe.com.

In `app/views/settings/show.html.erb`, find the button_to for plan changes and make sure it looks like:
```erb
<%= button_to "Upgrade",
    change_plan_settings_path(plan: plan[:key]),
    method: :post,
    form: { data: { turbo: "false" } },
    class: "..." %>
```

## PART 2: ONBOARDING STEP 2 LEFT PANEL

### Problem
The left panel in Step 2 shows a card with the workspace name and two gray placeholder lines. It looks like a loading skeleton or broken UI. Replace with actual useful content.

### Fix
In `app/views/layouts/onboarding.html.erb`, find the `elsif step == 2` section (around line 52) and replace the skeleton mockup with real content:

```erb
<% elsif step == 2 %>
  <div class="bg-white/5 rounded-xl p-4 border border-white/10">
    <div class="flex items-center gap-2 mb-3">
      <div class="w-6 h-6 bg-emerald-500/20 rounded flex items-center justify-center text-emerald-400 text-xs font-bold">FM</div>
      <span class="text-stone-300 text-sm font-medium"><%= current_account.name.presence || "Your Workspace" %></span>
    </div>
    <% if current_account.plan.present? %>
      <div class="flex items-center gap-2 mb-2">
        <span class="text-xs text-stone-500">Plan:</span>
        <span class="text-xs font-semibold text-emerald-400"><%= current_account.plan.titleize %></span>
      </div>
    <% end %>
    <div class="text-xs text-stone-500 leading-relaxed">
      Your workspace URL will be where your team accesses FeedbackMind every day.
    </div>
  </div>
  <div class="mt-4 space-y-2">
    <div class="flex items-center gap-2 text-stone-400 text-xs">
      <svg class="w-3.5 h-3.5 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>
      Unique URL for your team
    </div>
    <div class="flex items-center gap-2 text-stone-400 text-xs">
      <svg class="w-3.5 h-3.5 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>
      Can be changed later in Settings
    </div>
    <div class="flex items-center gap-2 text-stone-400 text-xs">
      <svg class="w-3.5 h-3.5 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>
      Invite team members after setup
    </div>
  </div>
```

## PART 3: BETTER ERROR MESSAGES FOR OAUTH

### Problem
When Jira shows "Access denied" or Typeform shows "403 Forbidden", the user doesn't know what to do. We should show clear instructions.

### Fix
In `app/controllers/source_connections_controller.rb`, update the `jira_callback` and `typeform_callback` rescue blocks to show more helpful error messages:

```ruby
# In jira_callback rescue
rescue => e
  Rails.logger.error "[OAuth] Jira callback error: #{e.message}"
  error_msg = if e.message.include?("access_denied") || e.message.include?("forbidden")
    "Jira access denied. Please verify: 1) Your Jira app has the callback URL https://5.161.238.195.sslip.io/sources/callback/jira configured, 2) Your Atlassian account has access to a Jira site."
  else
    "Jira connection failed: #{e.message}"
  end
  redirect_path = session.delete(:return_to_onboarding) ? onboarding_path : sources_path
  redirect_to redirect_path, alert: error_msg
end
```

Also, add a note in the sources/new view and onboarding step 3 that shows the user what redirect URI to configure:

After each Connect button, add a small help link or tooltip:
```erb
<p class="text-[10px] text-stone-400 mt-1">
  Callback: <code class="bg-stone-100 px-1 rounded"><%= "https://5.161.238.195.sslip.io/sources/callback/#{src[:provider]}" %></code>
</p>
```

This only needs to show for Jira and Typeform (the custom OAuth flows).

## EXECUTION ORDER

1. Run the Stripe verification script (Step 1) FIRST — if price IDs are wrong, nothing else matters
2. Fix onboarding controller (Steps 2-3)
3. Fix settings controller (Step 4) and view (Step 5)
4. Fix onboarding layout left panel (Part 2)
5. Add better OAuth error messages (Part 3)
6. Commit all changes
7. Run `kamal env push && kamal deploy`
8. Check production logs: `kamal app logs --since 5m | grep -E "\[Stripe\]|\[OAuth\]"`

## FILES TO MODIFY
- `app/controllers/onboarding_controller.rb` — Add Stripe Checkout for paid plans
- `app/controllers/settings_controller.rb` — Verify Stripe flow works
- `app/views/settings/show.html.erb` — Fix button_to turbo attributes
- `app/views/layouts/onboarding.html.erb` — Fix Step 2 left panel
- `app/controllers/source_connections_controller.rb` — Better OAuth error messages
- `app/views/sources/new.html.erb` — Show callback URLs as help text
- `app/views/onboarding/_step_3.html.erb` — Show callback URLs as help text
- `.kamal/secrets` — Update if Stripe price IDs need changing
- `.env` — Update if Stripe price IDs need changing

You CAN create any new files needed (helpers, concerns, services, initializers, tests, etc.).
