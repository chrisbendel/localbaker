# Configure the Pay gem with Stripe
Pay.setup do |config|
  config.business_name = "LocalBaker"
  config.support_email = "LocalBaker <noreply@localbaker.com>"
  config.application_name = "LocalBaker"

  # Send emails for subscription events
  config.send_emails = true

  # Stripe is the only processor we use
  config.enabled_processors = [:stripe]
end

# Stripe configuration (Pay automatically reads STRIPE_* env vars)
Stripe.api_version = "2024-06-20"

# Sync user.plan when Stripe subscription status changes
ActiveSupport.on_load(:pay) do
  Pay::Webhooks.delegator.subscribe "stripe.customer.subscription.created", StripeSubscriptionSync.new
  Pay::Webhooks.delegator.subscribe "stripe.customer.subscription.updated", StripeSubscriptionSync.new
  Pay::Webhooks.delegator.subscribe "stripe.customer.subscription.deleted", StripeSubscriptionSync.new
end
