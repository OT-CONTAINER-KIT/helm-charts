# Outline Database Migration — Replacement Guide

> **Scenario:** Your external Postgres database at `192.168.8.39:5432` already has a
> small amount of current data, but you want to replace it entirely with a dump
> from the old server. This is the **safest and cleanest** approach when the current
> DB only has test data or a few rows you can afford to lose.

---

## Overview

1. Back up the current DB (safety net).  
2. Scale Outline to 0 replicas (stop all writes).  
3. Restore the dump to a **staging** DB.  
4. Swap staging → live (atomic rename, ~10–30 s downtime).  
5. Scale Outline back up.  
6. Drop the old DB once you are confident.

---

## Prerequisites

| Item | Value |
|---|---|
| Postgres host | `192.168.8.39` |
| Live database | `outline` |
| App user | `outline-db-user` |
| Dump file path | `/tmp/outline_migration.dump` (adjust if different) |
| K8s namespace | `docs` |

---

## Step 1 — Back up the current database

SSH to the Postgres host and create a backup **before** you touch anything.

```bash
ssh <user>@192.168.8.39
sudo su - postgres

pg_dump -Fc outline > /tmp/outline-current-backup-$(date +%Y%m%d-%H%M%S).dump
```

Keep this file until you confirm the migration is successful.

---

## Step 2 — Stop Outline

Run from your Kubernetes control machine:

```bash
kubectl scale deployment outline-outline --replicas=0 -n docs

# Wait until all pods are gone
kubectl wait --for=delete pod -l app=outline -n docs --timeout=120s
```

---

## Step 3 — Create the staging database + restore the dump

On the Postgres host (`192.168.8.39`):

```bash
sudo su - postgres
psql
```

```sql
-- Create a fresh staging DB owned by the app user
CREATE DATABASE outline_staging OWNER "outline-db-user";
\q
```

Restore the dump into staging:

```bash
pg_restore \
  -d outline_staging \
  --no-owner \
  --no-privileges \
  --verbose \
  /tmp/outline_migration.dump
```

> `pg_restore` may print harmless errors like "role does not exist" because we
> stripped ownership. Those are safe to ignore as long as the final line says
> something like "pg_restore: finished item …".

Apply grants so Outline can read/write:

```bash
psql -d outline_staging
```

```sql
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "outline-db-user";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "outline-db-user";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "outline-db-user";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "outline-db-user";
\q
```

---

## Step 4 — Swap staging → live (atomic rename)

This is the magic step. It renames the databases so the new data becomes
`outline` instantly.

```bash
sudo su - postgres
psql -d postgres
```

```sql
-- 1. Kill any lingering connections to both databases
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname IN ('outline', 'outline_staging')
  AND pid <> pg_backend_pid();

-- 2. Rename current DB to "outline_old" (your rollback safety net)
ALTER DATABASE outline RENAME TO outline_old;

-- 3. Rename staging to "outline" (now the live DB)
ALTER DATABASE outline_staging RENAME TO outline;
\q
```

**Downtime so far:** only the time it took to run those three SQL commands
(~1–3 seconds).

---

## Step 5 — Verify the new database

Test as the app user — this is exactly what Outline will do when it starts:

```bash
psql "postgresql://outline-db-user:Outline_2026_safe@localhost:5432/outline"
```

```sql
-- List tables
\dt

-- Check key counts (these should match the old server)
SELECT COUNT(*) FROM documents;
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM teams;
SELECT COUNT(*) FROM attachments;
\q
```

If the counts look right, proceed. If not, you can roll back (see Step 8).

---

## Step 6 — Start Outline

Back on the Kubernetes control machine:

```bash
kubectl scale deployment outline-outline --replicas=2 -n docs
kubectl rollout status deployment/outline-outline -n docs
```

Check for healthy pods and no DB errors:

```bash
kubectl get pod -n docs -l app=outline
kubectl logs -n docs -l app=outline --tail=30
```

Open Outline in your browser, log in, and confirm documents and attachments are
visible.

---

## Step 7 — Post-migration cleanup

Once you have used Outline for a day or two and everything is stable, delete the
old database and staging artefacts:

```bash
ssh <user>@192.168.8.39
sudo su - postgres

-- Drop the old database (this frees the disk space)
psql -c "DROP DATABASE IF EXISTS outline_old;"

-- Optional: remove the dump file if you are tight on disk
rm /tmp/outline_migration.dump
```

---

## Step 8 — Rollback (if something went wrong)

Because we kept `outline_old`, you can revert in seconds:

```bash
sudo su - postgres
psql -d postgres
```

```sql
-- Kill connections
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname IN ('outline', 'outline_old')
  AND pid <> pg_backend_pid();

-- Swap back
ALTER DATABASE outline RENAME TO outline_staging_broken;
ALTER DATABASE outline_old RENAME TO outline;
\q
```

Then restart Outline:

```bash
kubectl rollout restart deployment/outline-outline -n docs
kubectl rollout status deployment/outline-outline -n docs
```

---

## Full script (copy-paste ready)

Save this as `db-replace.sh`, edit the `PG_HOST` variable, and run it from a
machine that has both `kubectl` and `ssh` access.

```bash
#!/bin/bash
set -euo pipefail

PG_HOST="192.168.8.39"
PG_USER="postgres"
DB_NAME="outline"
DUMP_FILE="/tmp/outline_migration.dump"
NAMESPACE="docs"
DATE=$(date +%Y%m%d-%H%M%S)

echo "=== 1. Scale Outline down ==="
kubectl scale deployment outline-outline --replicas=0 -n $NAMESPACE
kubectl wait --for=delete pod -l app=outline -n $NAMESPACE --timeout=120s

echo "=== 2. Backup current DB ==="
ssh "$PG_USER@$PG_HOST" "sudo -u postgres pg_dump -Fc $DB_NAME > /tmp/outline-current-backup-${DATE}.dump"

echo "=== 3. Create staging + restore dump ==="
ssh "$PG_USER@$PG_HOST" "sudo -u postgres psql -c \"CREATE DATABASE outline_staging OWNER \\\"outline-db-user\\\";\""
ssh "$PG_USER@$PG_HOST" "sudo -u postgres pg_restore -d outline_staging --no-owner --no-privileges --verbose $DUMP_FILE"

echo "=== 4. Apply grants ==="
ssh "$PG_USER@$PG_HOST" "sudo -u postgres psql -d outline_staging -c \"GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \\\"outline-db-user\\\";\""
ssh "$PG_USER@$PG_HOST" "sudo -u postgres psql -d outline_staging -c \"GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO \\\"outline-db-user\\\";\""

echo "=== 5. Swap databases ==="
ssh "$PG_USER@$PG_HOST" "sudo -u postgres psql -d postgres -c \"
  SELECT pg_terminate_backend(pid)
  FROM pg_stat_activity
  WHERE datname IN ('$DB_NAME', 'outline_staging') AND pid <> pg_backend_pid();
\""
ssh "$PG_USER@$PG_HOST" "sudo -u postgres psql -d postgres -c \"ALTER DATABASE $DB_NAME RENAME TO outline_old;\""
ssh "$PG_USER@$PG_HOST" "sudo -u postgres psql -d postgres -c \"ALTER DATABASE outline_staging RENAME TO $DB_NAME;\""

echo "=== 6. Scale Outline up ==="
kubectl scale deployment outline-outline --replicas=2 -n $NAMESPACE
kubectl rollout status deployment/outline-outline -n $NAMESPACE

echo "=== Done ==="
echo "Verify:  kubectl logs -n $NAMESPACE -l app=outline --tail=30"
echo "Rollback: rename outline_old back to $DB_NAME if needed."
```

---

## Quick checklist

- [ ] `pg_dump` backup of current DB created  
- [ ] Outline scaled to 0 replicas  
- [ ] `outline_staging` created and dump restored  
- [ ] Grants applied to staging  
- [ ] Databases swapped (`outline` → `outline_old`, `outline_staging` → `outline`)  
- [ ] Table counts verified  
- [ ] Outline scaled back to 2 replicas  
- [ ] Pods healthy and logs show no DB errors  
- [ ] Outline UI loads correctly  
- [ ] `outline_old` dropped after confidence period
