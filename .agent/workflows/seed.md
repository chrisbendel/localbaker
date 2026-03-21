---
description: How to seed the database with demo data
---
// turbo
1. Run the seed script to populate the database with a test baker, store, products, and orders:
```bash
bin/rails db:seed
```

2. (Optional) Reset and seed for a completely fresh start:
```bash
bin/rails db:reset
```

### Test Accounts
- **Baker**: `baker@example.com`
- **Buyer 1**: `buyer1@example.com`
- **Buyer 2**: `buyer2@example.com`

### Accessing the Store
The seeded store is located at: `/s/the-crusty-loaf`
