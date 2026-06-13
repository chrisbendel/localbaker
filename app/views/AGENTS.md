# Views & Partials — Rules

Keep partials pure, simple, single-purpose. Prefer WET over conditional cleverness.

- **No mode flags.** A partial never takes `mode:`/`variant:`/`type:` that changes its structure. Two simple partials beat one conditional partial.
- **Optional locals via `||=` defaults at the top of the partial** — never `local_assigns[:key]`. The defaults double as documentation of accepted locals. (`size:`-style styling parameters are fine; structural flags are not.)
- **Extract partials only for true reuse**: 1 place = inline, 2+ places = partial. A distinct component (button, badge, card) may be extracted at first use to establish convention.
- Use collection rendering (`render "card", collection:, as:`) over manual loops.
- **No inline `style=` attributes, ever.** Classes + tokens only.
- Layouts: `application` (all pages), `bakery` (baker dashboard). No conditional logic inside layouts.
- Don't unit-test partials — system tests cover rendering.
