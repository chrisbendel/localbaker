---
description: Coding principles for LocalBaker (Karpathy discipline + grug-brain anti-complexity)
---

# Code Principles

LocalBaker is a small Rails app maintained by one person. There is no headcount to absorb accidental complexity. Default to the boring, obvious solution.

## Discipline (how to execute a change)

1. **Think before coding.** Know what "done" looks like, concretely. If multiple valid approaches exist, name 2–3 and recommend one before writing code. Ask about uncertainty now, not after the diff.
2. **Simplicity first.** Minimum code that solves the problem. No unrequested features, no speculative options, no "might be useful later." Use built-in Rails helpers and existing CSS primitives before writing anything custom.
3. **Surgical changes.** Touch only what the goal requires. Match existing style. No drive-by refactors, no fixing unrelated code, no removing pre-existing dead code. Every line in the diff serves the stated goal.
4. **Goal-driven.** Turn vague asks into verifiable criteria ("error appears inline next to the field"), implement to that, verify with `bin/validate` or a manual browser pass.

## Anti-complexity (what not to build)

- **Say no.** Push back — with reasoning — on unclear features, options with no second caller, abstractions for hypothetical futures, dependencies replacing ~20 lines, refactors bundled into unrelated changes. Chris prefers the conversation to the diff.
- **Ship the boring version first.** It tells you whether the elaborate version is even needed.
- **Inline first; extract when it hurts.** Three similar blocks is not yet a pattern.
- **DRY is a tool, not a religion.** Code that looks identical but exists for different reasons should stay separate.
- **Locality of behavior beats neat layering** at this codebase size — keep logic near the thing it controls.
- **Profile, don't guess.** Rails bottlenecks are N+1s, missing indexes, or sync third-party calls — not micro-optimizations.
- **Chesterton's Fence.** Code whose purpose isn't obvious is there for a reason you don't yet see — find it (git blame, grep callers, ask) before deleting. Doubly true near payment/auth flows and validations.
- **If it doesn't fit in your head**, simplify until it does — don't fake confidence and ship.
- **Favor integration tests over mocked unit tests.** Mocks lie; integrated paths don't.
