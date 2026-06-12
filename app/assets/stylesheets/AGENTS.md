# Stylesheets — Design System Constraints

The design system is intentionally minimal and **closed**. Resist expansion. `application.css` is the source of truth for tokens and classes — this file only records the rules that protect the system.

- **Exactly three spacing sizes**: `--sp-sm` / `--sp-md` / `--sp-lg`, mirrored by `.stack-*` / `.group-*` primitives. Never add a size silently — if genuinely blocked, stop and explain which sizes you tried and why they fail.
- **New CSS classes are a last resort.** Check existing classes, then existing primitives + modifiers. A new class needs 2+ usage sites and a justifying comment.
- **No hardcoded values in views**: colors and spacing come from `:root` tokens; no inline `style=`; no raw hex/rem/px in templates.
- Warm/earthy monochrome palette, three button variants, 2px radius (9999px pills). The limitation is a feature — don't add "just one little variant."
- Update this file only when a constraint changes — never to document class names or token values.
