# Shop Controllers — Customer-Facing Domain Knowledge

This namespace handles the public storefront and customer ordering flow.

## Controllers

| Controller | Responsibility |
|---|---|
| `EventsController` | Public event browsing within a store |
| `OrderItemsController` | Add, update, remove items from a customer's order (cart) |
| `OrdersController` | Order confirmation and customer order history |
| `NotificationsController` | Subscribe/unsubscribe from store email notifications |

Also related (not in `Shop::` namespace):
- `ShopController` — public store homepage (`/s/:slug`)
- `PublicUnsubscribesController` — token-based unsubscribe (no auth required)

## Public vs. Authenticated Routes

- **Public**: store page, event listing, individual event page — no login required
- **Authenticated**: placing or modifying an order — requires `require_authentication!`

## Inventory Race Condition

`OrderItemsController` uses `with_lock` when adding or updating order items to prevent overselling. **Never remove this lock.** `EventProduct#remaining` and `#sold` are calculated fields (not stored columns) — always recompute them within the lock.

## One Order Per User Per Event

A user can have at most one `Order` per `Event`. This is enforced at the model level. The controller finds-or-creates the order on first item addition.

## Email Notifications

`StoreNotification` records an email subscription for a store. Unsubscribe uses a token (`unsubscribe_token`) — no authentication required. The unsubscribe route lives in `PublicUnsubscribesController`, not `Shop::`.

## Views

```
shop/_store_hero.html.erb      — store name + back link
shop/_event_card.html.erb      — public event card
shop/_event_details.html.erb   — event info on order page (pickup location + maps link)
shop/_product_card.html.erb    — product card; .sold-out opacity when unavailable
shop/_order_summary.html.erb   — order panel; native <select> for qty; pickup line at bottom
```
