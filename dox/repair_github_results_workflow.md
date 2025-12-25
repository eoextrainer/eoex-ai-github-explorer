# Repair Workflow: github_results Table

## Savepoint: 2025-12-25

### 1. Primary Fix: Add UNIQUE Constraint
- Migration file: dox/repair_github_results_unique.sql
- Command:
  ```sh
  PGPASSWORD=Password123 psql -U explorer -h localhost -d explorer_db -f dox/repair_github_results_unique.sql
  ```
- Purpose: Enables ON CONFLICT (url) DO NOTHING logic for batch inserts.

### 2. Fallback Patch: Remove ON CONFLICT
- Patch file: dox/repair_github_results_no_on_conflict.patch
- Command:
  ```sh
  patch -p1 < dox/repair_github_results_no_on_conflict.patch
  ```
- Purpose: Uses WHERE NOT EXISTS for inserts if UNIQUE constraint cannot be added.

### Usage
- Always try the migration first.
- If migration fails, apply the patch and restart backend.

### Reference
- DATABASE_URL: postgresql://explorer:Password123@localhost:5432/explorer_db
- Table: github_results
- Savepoint: 2025-12-25
