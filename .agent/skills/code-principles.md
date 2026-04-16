---
description: Coding principles for LocalBaker (Andrej Karpathy's framework, adapted)
---

# Code Principles Skill

These principles reduce mistakes, keep diffs clean, and prevent speculative overengineering. They apply to every code change.

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
