# Views & Partials — Rendering Philosophy

**Keep partials pure, simple, and single-purpose.** Prefer WET (write everything twice) over complex conditional logic.

## Partial Philosophy

### Rule 1: No Mode Flags or Variants
Partials must not accept `mode:`, `variant:`, `type:`, or similar flags that conditionally render different structures.

❌ **Bad**:
```erb
<%= render 'product_card', product: @product, mode: 'compact' %>
<!-- Inside _product_card.html.erb -->
<% if mode == 'compact' %>
  <div class="card-compact"><%= product.name %></div>
<% else %>
  <div class="card"><%= product.name %></div><p><%= product.description %></p>
<% end %>
```

✅ **Good** (two simple partials):
```erb
<%= render 'product_card', product: @product %>
<%= render 'product_card_compact', product: @product %>
```

**Why**: Conditional partials are harder to read, test, and maintain. Two clear partials are better than one complex one. This aligns with our design philosophy: clarity over cleverness.

### Rule 2: Optional Parameters via ||=, Not local_assigns
Use explicit defaults at the top of the partial:

✅ **Good**:
```erb
<% size ||= 'md' %>
<% include_description ||= true %>

<div class="card card-<%= size %>">
  <h3><%= product.name %></h3>
  <% if include_description %>
    <p><%= product.description %></p>
  <% end %>
</div>
```

❌ **Bad**:
```erb
<div class="card card-<%= local_assigns[:size] || 'md' %>">
  ...
</div>
```

**Why**: `||=` is explicit and readable. `local_assigns[:key]` is cryptic and makes it unclear what locals a partial accepts.

### Rule 3: One Job Per Partial
A partial should render one thing well. If you find yourself thinking "I could use this for X or Y," you probably need two partials.

✅ **Examples of good scope**:
- `_product_card.html.erb` — renders a single product card
- `_order_summary.html.erb` — renders the customer's order total + items
- `_event_badge.html.erb` — renders a small status badge

❌ **Examples of creep**:
- A partial that renders products OR orders depending on a flag
- A partial that handles both desktop and mobile layout (use CSS + media queries instead)
- A partial with 6+ parameters

### Rule 4: Partials Are for True Reuse
Don't extract a partial for code that appears in only one place. The partial might seem like it "will be reused later," but it won't, and it adds indirection.

If something appears:
- **1 place**: Keep it inline in the view
- **2+ places**: Extract to a partial
- **5+ places**: Maybe refactor the structure

### Rule 5: Use Collections When Rendering Multiple Items
Rails collection rendering is cleaner:

✅ **Good**:
```erb
<%= render 'product_card', collection: @products, as: :product %>
```

Instead of:
```erb
<% @products.each do |product| %>
  <%= render 'product_card', product: product %>
<% end %>
```

## Layout & Structure

### Layouts
- `layouts/application.html.erb` — All pages (header, toast, footer)
- `layouts/bakery.html.erb` — Baker-only pages (dashboard, events, settings)

Layouts use `<%= yield %>` for page content. No conditional logic inside layouts.

### Naming Conventions
- Partials start with underscore: `_product_card.html.erb`
- Prefer descriptive names over abbreviations: `_product_card` not `_prod_card`
- Group related partials in subdirectories: `shop/_product_card.html.erb`, `shop/_event_card.html.erb`

### No Inline Styles
All styling via CSS classes and tokens (`:root` custom properties). No `style=` attributes. Ever.

```erb
<!-- Good -->
<div class="card stack-lg">
  <%= @product.name %>
</div>

<!-- Bad -->
<div style="padding: 2rem; margin-bottom: 1rem;">
  <%= @product.name %>
</div>
```

## Forms & Components

### Form Partials
Forms are allowed to have a `size:` parameter for button sizing or input size variants. This is fine because it's purely a styling concern, not a structural change:

```erb
<% size ||= 'md' %>
<button class="button button-<%= size %>"><%= label %></button>
```

This is not a "mode flag" — it's a styling parameter. Use it for minor visual variations.

### Local Assigns
Always declare your expected locals at the top. This serves as documentation:

```erb
<!-- What this partial expects -->
<% product ||= nil %>
<% show_price ||= true %>

<div class="product-card">
  <h3><%= product.name %></h3>
  <% if show_price %>
    <p class="price"><%= product.price_formatted %></p>
  <% end %>
</div>
```

## When to Inline vs. Extract

| Situation | Do What |
|---|---|
| Code appears in only one place | Inline in the view |
| Code appears in 2+ places, simple logic | Extract to partial |
| Code is a distinct component (button, badge, card) | Extract even if used once (establishes convention) |
| You're tempted to add a mode flag | Use two partials instead |
| Different contexts need slightly different HTML | Two partials, not conditionals |

## Testing Views

System tests (`test/system/`) use `sign_in_via_browser` to authenticate and then click/navigate real HTML. View partials are tested implicitly via system tests — if the HTML renders wrong, tests catch it.

Do not unit test partials. Test the full page rendering via system tests.
