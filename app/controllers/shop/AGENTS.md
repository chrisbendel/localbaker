# Shop Controllers — Customer-Facing Domain Knowledge

This namespace handles the public storefront and customer ordering flow.

## Controllers

| Controller | Responsibility |
|---|---|
| `EventsController` | Public event browsing — renders the order form or summary |
| `OrdersController` | Single-form order placement, update, and cancellation |
| `NotificationsController` | Subscribe/unsubscribe from store email notifications |

Also related (not in `Shop::` namespace):
- `ShopController` — public store homepage (`/s/:slug`)
- `PublicUnsubscribesController` — token-based unsubscribe (no auth required)

## Public vs. Authenticated Routes

- **Public**: store page, event listing, individual event page — no login required
- **Authenticated**: placing, updating, or cancelling an order — requires `require_authentication!`

## Order model — no cart, no pending state

An `Order` exists only when a customer has committed. There is no intermediate
"cart" or "pending" state. `OrdersController#create` builds the `Order` and all
its `OrderItem`s atomically from a single form submission.

- **Create**: POST `/shop/:slug/events/:event_id/order` with `items[<product_id>] = qty`
- **Update**: PATCH same path — replaces all items on the existing order
- **Cancel**: DELETE same path — destroys the order and emails the customer

## Inventory Race Condition

`OrdersController#create` and `#update` lock each touched `EventProduct` row
with `FOR UPDATE` inside a transaction, then compare requested quantities
against `product.remaining`. On update, existing items are wiped first so
remaining stock is computed against the new order shape, not the old one.
**Never remove the lock.**

## One Order Per User Per Event

A user can have at most one `Order` per `Event`. Enforced at both the model
level (`validates uniqueness`) and the database level (unique composite index).

## Email Notifications

`StoreNotification` records an email subscription for a store. Unsubscribe uses
a token (`unsubscribe_token`) — no authentication required. The unsubscribe
route lives in `PublicUnsubscribesController`, not `Shop::`.

## Views

```
shop/_store_hero.html.erb      — store name + back link
shop/_event_card.html.erb      — public event card
shop/_event_details.html.erb   — event info on order page (pickup location + maps link)
shop/_order_form.html.erb      — single-form checkout (used for create + update)
shop/_order_summary.html.erb   — committed-order panel with Update / Cancel actions
```
