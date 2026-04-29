---
description: Coding principles for LocalBaker (Karpathy's discipline + grug-brain anti-complexity)
---

# Code Principles Skill

These principles reduce mistakes, keep diffs clean, and prevent speculative overengineering. They apply to every code change.

Two complementary lenses:
1. **Karpathy-style discipline** (sections 1–4) — *how* to execute a change cleanly: think first, stay simple, stay surgical, drive toward a measurable goal.
2. **Grug-brain anti-complexity** (section 5) — *what not to build*: complexity is the enemy, say no, defer abstractions, prefer the boring version.

Use both. Discipline keeps the diff clean; grug keeps the diff from existing in the first place when it shouldn't.

## 1. Think Before Coding

**Surface assumptions and options upfront.** Don't proceed silently into uncertainty.

**Before writing code:**
- [ ] Do I understand what "done" looks like? (Not vague like "add validation" — specific like "fields X, Y, Z are required; show errors inline")
- [ ] Are there multiple valid approaches? If yes, describe 2–3 and ask which one you prefer.
- [ ] Do I need to modify the database? (If yes, I need to create a migration, not edit `db/schema.rb` directly)
- [ ] Do I understand the existing pattern? (Controllers, models, partials, CSS tokens — all have conventions here)
- [ ] Am I uncertain about anything? Ask now, not after the diff is done.

**Example (Good)**:
> I can add this validation two ways:
> 1. In the model (`validates :name, presence: true`) — runs in Rails console and API
> 2. In the controller (`redirect if params[:name].blank?`) — only on web forms
> 
> For this form, I'd suggest option 1 (model) so it's enforced everywhere. Correct?

**Example (Bad)**:
> Adding validation. (Proceeds without clarifying where or how)

---

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

**Rules:**
- No unrequested features. If you say "add a submit button," I add a submit button. Not a submit button + cancel button + loading state + error handling for edge cases you didn't mention.
- No unnecessary abstraction. A partial that's used once stays inline. A loop that iterates twice is not worth a helper method.
- No "this might be useful later." If you want it, ask for it.
- Match existing style. Don't refactor unrelated code or introduce new patterns.

**Rails-specific:**
- Use built-in Rails helpers (`number_to_currency`, `time_ago_in_words`) before writing custom formatting.
- Prefer model validations + error displays over controller guard clauses.
- Use `.stack` / `.group` CSS classes before writing custom flexbox.
- Don't create a partial for code that appears in one place.

**Example (Good)**:
```ruby
# Add a method. That's it.
def formatted_price
  number_to_currency(price_cents / 100.0)
end
```

**Example (Bad)**:
```ruby
# Over-engineered: private helper, error handling, type coercion
def formatted_price(precision: 2, currency: 'USD')
  return nil if price_cents.nil?
  (price_cents.to_f / 100.0).round(precision).to_s.prepend(currency)
rescue TypeError => e
  Rails.logger.warn("Price formatting failed: #{e.message}")
  "Error"
end
```

---

## 3. Surgical Changes

**Touch only what's necessary.** Match existing style. Don't refactor unrelated code.

**Rules:**
- If I'm adding a column, I create a migration. I don't rewrite the model while I'm at it.
- If I'm adding a partial, I don't fix the CSS on the parent while I'm at it.
- If I'm fixing a bug in controller A, I don't also clean up typos in controller B.
- Match the existing code style — indentation, variable naming, structure. Don't impose a different convention.
- Only remove code if YOUR change made it obsolete. Leave pre-existing dead code alone (it's not your PR's job to fix).

**Diff Quality Check:**
- Can a code reviewer understand exactly what changed without reading 10 files?
- Would a revert of this change break anything else?
- Does every line in the diff serve the stated goal?

**Example (Good)**:
```diff
+  validates :name, presence: true
```
(One line, solves the problem, matches existing validation style)

**Example (Bad)**:
```diff
+  validates :name, presence: true
+  # TODO: add email validation
+  validates :email, presence: true
+  validates :email, uniqueness: true
+  
+  def full_name
+    "#{first_name} #{last_name}"
+  end
+
+  def admin?
+    role == 'admin'
+  end
```
(Three unrelated features in one PR; includes a TODO; adds methods beyond the scope)

---

## 4. Goal-Driven Execution

**Transform abstract tasks into measurable success criteria. Iterate toward a verifiable goal.**

Instead of: "Add form validation"  
Say: "Users see an error if they submit without a name. The error appears inline next to the field. The error clears when they type."

Instead of: "Improve performance"  
Say: "The dashboard loads in <500ms and handles 100+ events without lag."

**Testing Loop:**
1. Define the goal (what does "done" look like?)
2. Write a test that would fail without the feature
3. Implement the feature to make the test pass
4. Run `bin/validate` — if it passes, you're done

**For Browser Features:**
1. Define the goal (e.g., "Users can add items to their cart with a plus button; qty shows inline")
2. Open the browser and manually test
3. Ask: Is it done? If not, what's missing?

**Example (Good)**:
> Goal: New users see an onboarding checklist on the dashboard. Each item has a checkbox. Checking it persists. The checklist disappears once all items are checked.
> 
> Test: Sign in as new user → checklist appears → click item → refresh page → item still checked → check remaining items → checklist gone

**Example (Bad)**:
> Goal: Improve onboarding.
> (Too vague. What does "improved" mean? Faster? More complete? More visible?)

---

## Putting It Together

**A good PR workflow:**

1. **Think** — Ask clarifying questions before coding
2. **Define success** — What does "done" look like?
3. **Surgical** — Touch only what's necessary
4. **Simple** — Minimum code that solves the problem
5. **Test** — Run `bin/validate`; verify manually if it's UI
6. **Ask for feedback** — Is it actually done?

**Success indicators:**
- Diffs are small and focused
- No "while I'm at it" refactoring
- Tests pass on first or second iteration
- Code reviewer understands the change immediately

---

## 5. Grug Brain Wisdom

Adapted from [grugbrain.dev](https://grugbrain.dev/). The principles above tell you *how* to make a change cleanly. Grug tells you *what not to build in the first place* — and gives you the spine to push back when something would make the codebase worse.

### The Core Belief: Complexity Is the Enemy

Every line of code, every abstraction, every dependency is a future maintenance cost. **Complexity compounds.** A small unjustified abstraction today is a large untangling job in six months. When evaluating any change, the first question is not "is this clever?" but "does this make the system harder to understand?"

LocalBaker is a small Rails app maintained by one person. We do not have the headcount to absorb accidental complexity. Default to the boring, obvious solution.

### Say No

The strongest tool against complexity is refusing to add things. Push back — politely, with reasoning — when:

- A feature has unclear value or unclear users
- A "configurable option" has no second caller asking for it
- An abstraction is being introduced for a hypothetical future case
- A new dependency replaces ~20 lines of straightforward code
- A refactor is bundled into an unrelated change

If Chris asks for X and you see X will make the system meaningfully worse, say so before writing the code. He'd rather have the conversation than the diff.

### 80/20 — Ship the Boring Version First

When a request has an elaborate "right" solution and a crude "good enough" solution, propose both and recommend the crude one unless there's a concrete reason for the elaborate one. The crude version ships, gets used, and tells you whether the elaborate version is even needed.

### Don't Abstract Until the Cut Point Is Obvious

Wait for repetition to scream at you. Three similar blocks of code is not yet a pattern — it's three blocks of code. Six similar blocks across two controllers, with the same shape and the same reason for existing, is a pattern. Premature abstraction is harder to undo than duplication.

A partial, helper, concern, or service object should only exist when its absence causes friction. **Inline first. Extract when it hurts.**

### Locality of Behavior > Separation of Concerns

When code that belongs together is scattered across files, debugging becomes archaeology. Prefer keeping logic near the thing it controls — a Stimulus controller next to its template, validation on the model that owns the data, a query in the controller action that uses it (until it's used twice).

This trades "neat layering" for "I can find everything in one place." For a codebase this size, that's the right trade.

### DRY Is a Tool, Not a Religion

Two pieces of code that look identical but exist for *different reasons* should stay separate — they will diverge. Eliminating duplication that isn't really duplication creates an abstraction that fights you every time the underlying reasons drift apart. Repeated code is cheap; the wrong abstraction is expensive.

### Don't Optimize Without Measuring

If you have not profiled, you do not know where the bottleneck is. For a Rails app, the bottleneck is almost always: N+1 queries, missing indexes, or a synchronous third-party call that should be a job. It is almost never: a loop that could be a hash lookup, a string concat, or a "more efficient" data structure.

Add `includes` to fix N+1s when you see them. Don't rewrite working code on a hunch.

### Chesterton's Fence

If you find code whose purpose isn't obvious, **assume it's there for a reason you don't yet see.** Find the reason before deleting it. Git blame, grep for callers, ask Chris. The "obviously useless" code is sometimes load-bearing in a non-obvious way.

This is doubly true for: validation rules, callbacks, weird-looking conditionals near payment/auth flows, and seemingly redundant CSS resets.

### It's OK to Say "This Is Too Complex for Me"

If a piece of the system genuinely doesn't fit in your head, the answer is not to fake confidence and ship something. The answer is to say so, simplify the surrounding code until it does fit, and then make the change. Confusion is a signal — usually that the code is bad, not that you are.

### Tests: Favor Integration Over Unit

A system test that exercises the real flow (user signs in, places order, sees confirmation) catches more real bugs per line of test code than a dozen mocked unit tests. Mocks lie; integrated paths don't. See `test/AGENTS.md` for the testing strategy already in place — it leans this way deliberately.

### Tools Compound

Time spent learning the debugger, the Rails console, `bin/validate`, and the actual error messages pays back many times over. Don't pattern-match a fix from a similar-looking error — read the stack trace, open the file, understand the failure.

### Summary Aphorisms (for fast recall)

- **Complexity very, very bad.** First question: does this make the system harder to understand?
- **No is a feature.** Refuse what shouldn't exist.
- **Boring beats clever.** Ship the obvious version.
- **Inline first. Extract when it hurts.**
- **Three is not a pattern.**
- **Read the fence before tearing it down.**
- **Profile, don't guess.**
- **If it doesn't fit in your head, the code is wrong, not you.**
