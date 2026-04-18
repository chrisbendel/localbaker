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

### Premium Features (Pro Tier Only)

These emails provide additional value beyond core transactional feedback. They are premium features that differentiate the pro tier.

- **Pickup Reminder** — Sent 24 hours before event pickup
  - File: `app/mailers/order_mailer.rb` → `pickup_reminder`
  - Triggered: `app/jobs/pickup_reminder_job.rb:7` (pro-only gate)
  - Recipient: Customer (order.user)
  - Rationale: Convenience feature that adds value; only valuable when baker is active

- **New Event Notification** — Sent to store followers when baker publishes an event
  - File: `app/mailers/store_mailer.rb` → `new_event`
  - Triggered: `app/controllers/dashboard/events_controller.rb:44` (pro-only gate)
  - Recipient: Store followers (subscribers)
  - Rationale: Marketing/engagement feature that drives traffic; not essential

### System Emails (No Tier Gate)

- **Feedback/Contact Form** — Received by admin
  - File: `app/mailers/contact_mailer.rb` → `feedback`
  - Recipient: Admin (chrissbendel@gmail.com)

## Adding New Transactional Emails

When adding a new email feature, first determine its classification:

1. **Does this provide essential feedback about an action the user took?**
   - Yes → Core Transactional (all tiers)
   - No → Continue to next question

2. **Is this a marketing, convenience, or premium feature?**
   - Yes → Premium (pro-only with tier gate)
   - No → Evaluate case-by-case

3. **Add the tier gate in the appropriate location:**
   - Controller action: For immediate user-facing feedback
   - Model method: For model-triggered emails
   - Job: For scheduled/background emails

Example tier gate:
```ruby
if event.store.user.pro?
  SomeMailer.with(data: @data).some_email.deliver_later
end
```

## Rationale

**Core transactional emails are not premium features** because:
- They provide essential user feedback, not added convenience
- Customers expect confirmation that their action succeeded
- Removing them hurts UX for free-tier users without providing clear baker value
- They are scalable and low-cost to send

**Premium features provide additional value** because:
- They are convenience or marketing tools
- They incentivize upgrading to pro tier
- They justify the pro subscription cost
- They can be disabled without breaking core functionality
