# Stylesheets — Design System

**The design system is intentionally minimal and closed. Do not expand it without explicit instruction.**

## Design Tokens (`application.css` `:root`)

```css
--font             /* "DM Sans", system-ui — loaded via Google Fonts */
--text             /* #1a1612 — primary text */
--text-muted       /* #706860 — secondary text (warm gray) */
--border           /* #ddd8d2 — default borders */
--border-strong    /* #aaa49e — emphasized borders */
--bg               /* #f5f2ee — warm off-white */
--bg-subtle        /* #edeae5 — cards, panels */
--success          /* var(--text) — monochrome */
--danger           /* var(--text) — monochrome */
--sp-sm            /* 0.5rem */
--sp-md            /* 1rem */
--sp-lg            /* 2rem */
--radius           /* 3px */
--radius-full      /* 9999px — pills */
```

The palette is earthy/warm-toned. All values come from these tokens — no hardcoded colors or spacing.

## Layout Primitives

| Class | Purpose |
|---|---|
| `.container` | Max-width 720px, centered, horizontal padding |
| `.stack-sm` | Vertical flex column, `gap: --sp-sm` |
| `.stack` | Vertical flex column, `gap: --sp-md` |
| `.stack-lg` | Vertical flex column, `gap: --sp-lg` |
| `.group-sm` | Horizontal flex row, `gap: --sp-sm` |
| `.group` | Horizontal flex row, `gap: --sp-md` |
| `.group-lg` | Horizontal flex row, `gap: --sp-lg` |
| `.flex-cols-2` | Responsive 2-column flex row (tiling) |
| `.page-header` | Row on desktop, stacked column on mobile (`≤600px`) |

## Components

| Class | Purpose |
|---|---|
| `.card` | Bordered box, `1px solid var(--border)`, minimal radius |
| `.card.sold-out` | Dimmed card (`opacity: 0.55`) for sold-out products |
| `.card-accent` | Card with a bold left border (event details) |
| `.panel` | Subtle background container (`--bg-subtle`) |
| `.empty-state` | Dashed border centered placeholder with optional CTA |
| `.nudge` | Subtle next-step prompt (subtle bg + border) |
| `.badge` | Inline status label — variants: `.open`, `.closed`, `.draft` (uppercase, letter-spaced; no pill shape) |
| `.nav-order-count` | Small count bubble on the nav bag icon |

## Buttons

| Class | Purpose |
|---|---|
| `button` / `.button` | Default bordered button |
| `.primary` | Filled black button (primary CTA) |
| `.small` | Compact button size |
| `.secondary` | Muted/ghost button |
| `.danger` | Red-tinted destructive action |
| `.button-link` | Unstyled inline link-style button (used for `button_to`) |

## Typography Helpers

`.text-muted`, `.text-sm`, `.text-lg`, `.text-danger`, `.text-success`, `.font-bold`, `.text-center`, `.text-right`

## Tables

Global `table` styles apply to all tables. Use `.responsive-table` + `data-label="..."` on `<td>` for mobile card fallback (stacks rows at `≤600px`).

## Design System Constraints

### Spacing — NEVER add new sizes or variants

The spacing scale has exactly **three sizes**: `sm`, `(base)`, `lg`. The layout primitives mirror this exactly. This is a deliberate constraint.

**Prohibited without explicit user approval:**
- New spacing tokens (`--sp-xs`, `--sp-xl`, `--sp-2xl`, etc.)
- New layout class variants (`.stack-xs`, `.group-tight`, `.stack-xl`, etc.)
- New gap/spacing utility classes (`.gap-xs`, `.gap-md`, etc.)
- Inline `style=` attributes for spacing or layout

Before adding a new size, work through:
1. Would `sm` or `lg` be close enough? Slight visual difference is acceptable.
2. Can the parent or child be restructured to avoid the need?
3. Is the element itself the wrong choice?

If you genuinely cannot proceed without a new primitive, **stop and explain why** — state which sizes you tried and why they don't work. Do not add silently.

### CSS Classes — no new utilities without justification

Before adding any new CSS class, verify it doesn't already exist in `application.css`. A new class must:
- Solve a problem that cannot be solved with existing primitives + modifier classes (`.items-center`, `.justify-between`, etc.)
- Be used in at least two places — single-use styling belongs inline or as a component-specific rule

### Partials & `mode:` flags

Partials must not accept a `mode:` or `variant:` flag to render different structures. If two contexts need different markup, use two partials or inline the simpler case.

### Default parameters in partials

Use `<% variable ||= default %>` at the top of a partial for optional locals. Never use `local_assigns[:key]` — it bypasses the explicit default and makes the interface unclear.

### No inline styles

`style=` attributes are strictly forbidden. Use CSS classes and tokens.
