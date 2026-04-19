# Email Strategy

This document defines how transactional emails are classified and gated by user tier in LocalBaker.

## Classification

### Core Transactional Emails (All Tiers)

These emails provide essential feedback about actions the customer took. They are sent to all users regardless of tier because they are fundamental to the user experience.

- **Order Confirmation** — Sent to customer when they confirm an order
  - File: `app/mailers/order_mailer.rb` → `confirmation_email`
  - Triggered: `app/controllers/shop/orders_controller.rb:17`
  - Recipient: Customer (order.user)
  - Rationale: Confirms order was received and processed

- **Order Cancellation** — Sent to customer when they cancel a confirmed order
  - File: `app/mailers/order_mailer.rb` → `cancellation_email`
  - Triggered: `app/models/order.rb:44`
  - Recipient: Customer (order.user)
  - Rationale: Confirms cancellation was processed

- **Login Code** — Sent to user for passwordless authentication
  - File: `app/mailers/session_mailer.rb` → `login_code`
  - Triggered: `app/controllers/sessions_controller.rb`
  - Recipient: User (email)
  - Rationale: Required for authentication flow

- **Pickup Reminder** — Sent 24 hours before event pickup
  - File: `app/mailers/order_mailer.rb` → `pickup_reminder`
  - Triggered: `app/jobs/pickup_reminder_job.rb:7`
  - Recipient: Customer (order.user)
  - Rationale: Convenience feature that helps customers remember to pick up

- **New Event Notification** — Sent to store followers when baker publishes an event
  - File: `app/mailers/store_mailer.rb` → `new_event`
  - Triggered: `app/controllers/dashboard/events_controller.rb:44`
  - Recipient: Store followers (subscribers)
  - Rationale: Engagement feature that keeps followers informed of new offerings

### Premium Features (Pro Tier Only)

Currently none. Pricing differentiation is managed through:
- **Event limits**: Free tier limited to 3 active events; Pro tier unlimited
- **Delivery features**: Delivery zone configuration (Pro only)

*Note: If needed in the future, event notifications could be gated to Pro tier to incentivize subscription. See `app/controllers/dashboard/events_controller.rb` line 44.*

### System Emails (No Tier Gate)

- **Feedback/Contact Form** — Received by admin
  - File: `app/mailers/contact_mailer.rb` → `feedback`
  - Recipient: Admin (chrissbendel@gmail.com)

## Adding New Transactional Emails

**Current policy**: Send all transactional emails to all tiers. Pricing differentiation is handled through event limits, not email gates.

When adding a new email feature:

1. **Send to all users by default** (no tier gate)
2. **Only add a tier gate if**:
   - The feature would create unbounded email volume (not constrained by event limits)
   - It provides strategic value to pro tier beyond core functionality
   - Business metrics show it's worth differentiation

3. **If adding a tier gate**, place it in the appropriate location:
   - Controller action: For immediate user-facing feedback
   - Model method: For model-triggered emails
   - Job: For scheduled/background emails

Example tier gate (if needed):
```ruby
if event.store.user.pro?
  SomeMailer.with(data: @data).some_email.deliver_later
end
```

## Rationale

**All transactional and convenience emails are sent to all tiers** because:
- They provide essential user feedback on actions taken
- Customers expect confirmation that their action succeeded
- Email volume is naturally constrained by the **event limit** (3 for free tier, unlimited for pro)
- Pricing differentiation is managed through capacity (events) and features (delivery), not email gates

**Pricing model (free vs pro)**:
- **Free tier**: 3 active events max (natural email volume constraint)
- **Pro tier**: Unlimited events + delivery zone features
- Email gates are simplified: send all transactional emails to all users, let event limits manage volume
