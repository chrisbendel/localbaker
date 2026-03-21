# Product Decisions & Core Flows

This document tracks high-level product decisions and defines the core user flows to ensure consistent implementation.

## Core Flows

### 1. Baker Setup
- Sign up -> Redirect to Dashboard.
- Crate Store -> Choose slug, name, description.
- Create Event -> Set pickup date/time, orders close date/time.
- Add Products -> Name, Price, Quantity (Inventory control).
- Publish -> Make event visible on storefront.

### 2. Ordering
- Browse Storefront -> View list of published events.
- Select Event -> View products and availability.
- Add Items -> Immediate sync to database. Status is implicit (exists = ordered).

## User Experience Standards
- **Mobile-First Tables**: (Implemented) On small screens, tables collapse into "card" stacks using native CSS (`data-label`).
- **Modular Components**: Use Rails partials for all core UI elements (Store Hero, Product Cards, etc.) to ensure consistency.
- **Minimalist Styling**: Honor the "Bare-Bones" ethos by using native Flexbox/Grid and standard typography. Avoid excessive ad-hoc styling.
- **No Dropdowns**: (Enforced in AGENTS.md) Use direct links/buttons.
