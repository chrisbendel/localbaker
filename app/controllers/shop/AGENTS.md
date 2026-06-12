# Shop Controllers — Customer-Facing Rules

Public storefront + ordering flow. Browsing is public; placing/updating/cancelling an order requires authentication.

## Invariants — do not weaken

- **Inventory locking**: `OrdersController#create`/`#update` lock each touched `EventProduct` row (`FOR UPDATE`) inside a transaction before comparing against `remaining`. On update, existing items are wiped first so stock is computed against the new order shape. **Never remove the lock.**
- **No cart, no pending state**: an `Order` exists only when committed. Create builds the `Order` + all `OrderItem`s atomically from one form; cancel destroys and emails the customer.
- **One order per user per event** — enforced by model validation *and* a unique composite index.

## Subscriptions

Logged-out subscribe stores nothing: a signed token (`{email, store_id}`, 7-day expiry) goes out by email, and redeeming it creates the User + StoreNotification and signs them in. Row existence = confirmed subscriber. Unsubscribe is token-based via `PublicUnsubscribesController` (no auth).
