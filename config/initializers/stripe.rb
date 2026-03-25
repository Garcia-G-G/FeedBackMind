Stripe.api_key = ENV.fetch("STRIPE_SECRET_KEY", nil) || Rails.application.credentials.dig(:stripe, :secret_key)
