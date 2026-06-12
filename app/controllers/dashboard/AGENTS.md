# Dashboard Controllers — Baker-Facing Rules

- Every action requires authentication **and** ownership: manual `current_user == @store.user` guards (no authorization gem). Never skip or weaken these. Controllers inherit `Dashboard::BaseController`, which wires `require_authentication!` / `require_store!`.
- Events are **drafts** until `published_at` is set. Publishing an event with a repeat interval spawns the next draft automatically.
- `Store#onboarding_steps` / `#onboarding_complete?` track baker setup; the dashboard checklist is session-dismissible.
