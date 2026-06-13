# Shop Controllers — Customer-Facing Rules

Public storefront + ordering flow. Browsing is public; placing/updating/cancelling an order requires authentication.

## Invariants — do not weaken

- **Inventory checks are deliberately lock-free**: `save_order` wipes existing items and rebuilds inside a transaction, comparing against `remaining` without row locks — low traffic + honor system accepts rare oversell races (see the comment atop `OrdersController`). Don't add locks without evidence of real oversells.
- **Orders close enforcement**: create, update, and cancel are all rejected once `orders_open?` is false — both controller-side and in the UI.
- **No cart, no pending state**: an `Order` exists only when committed. Create builds the `Order` + all `OrderItem`s atomically from one form; cancel destroys and emails the customer.
- **One order per user per event** — enforced by model validation *and* a unique composite index.

## Subscriptions

Logged-out subscribe stores nothing: a signed token (`{email, store_id}`, 7-day expiry) goes out by email, and redeeming it creates the User + StoreNotification and signs them in. Row existence = confirmed subscriber. Unsubscribe is token-based via `PublicUnsubscribesController` (no auth).
