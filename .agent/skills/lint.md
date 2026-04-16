---
description: How to run linting and formatting
---
# Lint Skill

## Agent Instructions

Run StandardRB to check and fix style issues before committing.

## Standalone Mode

A developer running lint manually:

```bash
bundle exec standardrb          # check for issues (read-only)
bundle exec standardrb --fix    # auto-fix issues
bin/validate                    # lint + all tests (recommended before committing)
```

## Notes

- StandardRB is an opinionated Ruby style guide (based on RuboCop Standard). It has no config file — all rules are fixed.
- `--fix` rewrites files in place. Review the diff after running it.
- `bin/validate` runs lint first, then the full test suite. A clean lint run is required before the tests are considered passing.
