---
description: how to run linting and formatting
---
# Linting and Formatting Workflow

Use this workflow to ensure code style compliance.

1. Check for linting issues:
// turbo
```bash
bundle exec standardrb
```

2. Auto-fix linting issues:
// turbo
```bash
bundle exec standardrb --fix
```

3. **Full Validation** (RECOMMENDED: lint + all tests):
// turbo
```bash
bin/validate
```
