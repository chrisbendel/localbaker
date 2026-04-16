---
description: How to run database migrations
---
# Database Migration Skill

## Agent Instructions

Always generate a migration file for schema changes. Never edit `db/schema.rb` directly — it is auto-generated.

## Standalone Mode

A developer managing migrations manually:

```bash
bin/rails generate migration <MigrationName>   # create a new migration
bin/rails db:migrate                            # run pending migrations
bin/rails db:rollback STEP=1                    # undo the last migration
bin/rails db:prepare                            # setup + migrate + seed (idempotent)
```

## Common Pitfalls

- **Never commit `db/schema.rb` directly.** Schema changes must always have a corresponding migration file in `db/migrate/`. Without it, fresh deployments will fail trying to re-add columns that already exist. When reviewing PRs, flag any `schema.rb` changes without a matching migration.
- **Migration naming**: Use descriptive names that explain the change — `AddPublishedAtToEvents`, `CreateStoreNotifications`, not `UpdateTable`.
- **Rollback safety**: Destructive migrations (dropping columns, changing types) can lose data. Test rollback (`db:rollback`) before committing.
