# Dashboard Controllers — Baker-Facing Domain Knowledge

This namespace handles all baker-facing management. Every route here requires authentication and ownership verification.

## Controllers

| Controller | Responsibility |
|---|---|
| `EventsController` | Create, edit, publish, delete events |
| `EventProductsController` | Add, update, remove products within an event |
| `StoresController` | Create and edit the baker's store (name, slug, description) |
| `ProfilesController` | Edit baker profile settings |
| `PaymentsController` | Payment/subscription management |

## Ownership Pattern

Every action that touches a store, event, or product must verify the current user owns it:

```ruby
current_user == @store.user
```

There is no authorization gem — ownership checks are manual `before_action` guards. Never skip or weaken this check.

All routes here also require:
```ruby
before_action :require_authentication!
```

## Event Lifecycle

- Events are **drafts** until `published_at` is set.
- The dashboard groups events into: **Drafts** / **Taking orders** / **Upcoming**.
- Publishing an event with `repeat_cadence` automatically spawns the next draft.

## Views

```
dashboard/show.html.erb                  — baker hub; events grouped by status; onboarding checklist for new bakers
dashboard/event_products/_form.html.erb  — shared product form (new + edit)
```

## Onboarding

`Store#onboarding_steps` and `Store#onboarding_complete?` track setup progress. The onboarding checklist card on the dashboard is session-dismissible (hidden after the baker clicks dismiss, stored in the session).
