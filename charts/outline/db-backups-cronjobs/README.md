# Outline Postgres Backup — `db-backups-cronjobs/` (live production method)

Same 3-tier pattern as the file backups, but for the database — so you no
longer depend on the DBA. Dumps go to a **separate bucket**
`outline-db-backup` (file backups live in `outline-pvc-backup`).

## What runs in the cluster

| Object | Name (`-n docs`) | Schedule | Purpose |
|---|---|---|---|
| CronJob | `outline-db-backup-daily` | `30 2 * * *` (2:30 AM) | → `daily/`, keep 7 days |
| CronJob | `outline-db-backup-monthly` | `30 3 1 * *` (1st, 3:30 AM) | → `monthly/`, keep 365 days |
| CronJob | `outline-db-backup-yearly` | `30 4 1 1 *` (Jan 1st, 4:30 AM) | → `yearly/`, keep 1095 days (3y) |
| ConfigMap | `outline-db-backup-script` | — | `db-backup-script.sh`, shared by all three |

No new Secret: the Jobs read `DATABASE_URL` from the existing
`outline-postgres-external-secret` (same one the app uses) and MinIO creds
from `minio-backup-secret`. Image `postgres:17` (ships `pg_dump`/`psql`;
`mc` is downloaded at runtime from the fixed `.../aistor/mc/...` URL).
Schedules sit 30 min after the file backups; `concurrencyPolicy: Forbid`.

Each run: log server version → `pg_dump -Fp | gzip` → size sanity check
(refuses to upload dumps under 10 KB) → `mc cp` to
`outline-db-backup/<tier>/outline-db_<ts>.sql.gz` → `mc rm --older-than`
prunes that prefix.

Facts (21-Sep-2026 test runs): server is **PostgreSQL 16.14 (Percona)**,
dumped with pg_dump 17.11; dump is **~50 MB**, 31 tables with data, verified
as valid SQL containing `public.documents`.

## `.sql` vs `.dump` — what they are, when to use what

`pg_dump` has two main output formats. We use **plain SQL (`.sql.gz`)**.
Here's why:

| | Plain SQL (`-Fp`, `.sql` / `.sql.gz`) ← we use this | Custom format (`-Fc`, `.dump`) |
|---|---|---|
| What it is | Plain-text SQL (`CREATE TABLE`, `COPY ...`) | Compressed binary archive |
| Readable? | Yes — open it, grep it, diff it | No — needs `pg_restore` to inspect |
| Restore with | Any `psql` | Only `pg_restore` |
| Restore across versions (old → new, e.g. 14 → 18) | ✅ Works — restore with the **new** server's `psql` | ✅ Works — restore with the **new** server's `pg_restore` |
| Restore new → old (18 → 14) | ❌ Unsafe (either format — backups never go backward across majors) | ❌ Unsafe (same reason) |
| Single-table restore | Painful (edit the file) | Easy (`pg_restore -t tablename`) |
| Parallel restore | No | Yes (`pg_restore -j 4`) |
| Fits `psql -f` flows (like our `db-replace.sh`) | Yes, directly | No, needs conversion |

**The rule that matters:** always dump with tools **≥** the server version and
restore with the **target** server's tools. We run `pg_dump` 17 against
server 16, so today's dumps restore on 16, 17, 18… — a DBA upgrade can never
break them. (Backward — restoring an 18-era dump onto a 14 server — is
unsupported in both formats; but we only ever move lower → higher.)

**When would `.dump` be better?** If the DB grows to many GB (parallel
restore saves real time) or you routinely restore single tables. Today
(~50 MB, full-DB restores) plain SQL is simpler, inspectable, and plugs into
the existing staging-swap procedure — so `.sql.gz` it is.

## DB restore (from a MinIO dump)

Two runbooks, pick by situation:

* **DB is alive, rows were deleted by mistake** (e.g. pages deleted in the
  UI) → `restore-existing-db.md` — surgical row re-insert, no superuser,
  other data untouched.
* **DB is gone — or must be fully rewound** → `restore-deleted-db.md` —
  staging → swap on the DB host, zero DBA involvement.

Quick reference (full procedure in `restore-deleted-db.md`):

```bash
# 0. Freeze writers:
kubectl scale deployment outline-outline --replicas=0 -n docs

# 1. Fetch + unpack the dump you want (daily/monthly/yearly):
mc alias set minio-backup https://minio.ldc.opstree.dev:9000 <KEY> <SECRET> --api S3v4
mc ls --recursive minio-backup/outline-db-backup/
mc cp minio-backup/outline-db-backup/daily/outline-db_<ts>.sql.gz /tmp/restore.sql.gz
gunzip -c /tmp/restore.sql.gz > /tmp/outline_migration.sql

# 2-7. Same as db-replace.sh: staging restore, grants, swap, verify counts:
#   sudo -u postgres psql -c "DROP DATABASE IF EXISTS outline_staging;"
#   sudo -u postgres psql -c "CREATE DATABASE outline_staging OWNER \"outline-db-user\";"
#   sudo -u postgres psql -d outline_staging -f /tmp/outline_migration.sql
#   ... grants ... (see ../db-replace.sh steps 4-7, incl. row counts on
#   documents/users/teams and dropping outline_old)

# 8. Back online:
kubectl scale deployment outline-outline --replicas=2 -n docs
kubectl rollout status deployment/outline-outline -n docs
```

Post-major-upgrade notes (e.g. 16 → 18): after restore, `REINDEX` text
indexes if glibc changed (PG warns on collation mismatch), then `ANALYZE`.
Keep restoring as `postgres` superuser + granting to `outline-db-user`
(PG15+ locks down the `public` schema — the grant step covers it).

## Re-run / redeploy

```bash
cd charts/outline/db-backups-cronjobs
kubectl apply -f outline-db-backup-cronjob.yaml
kubectl get cronjob -n docs -l app=outline-db-backup

# Manual dump, per tier:
kubectl create job outline-db-backup-daily-manual-$(date +%s) --from=cronjob/outline-db-backup-daily -n docs
kubectl logs -n docs -l app=outline-db-backup,tier=daily --tail=60 -f

# Confirm in MinIO:
mc ls --recursive minio-backup/outline-db-backup/
```

## Troubleshooting

* Same `mc` download / `410 Gone` lessons as file backups apply — fixed URL
  is already in the script.
* `pg_dump: server version X; pg_dump version Y` errors → the image is older
  than the server; bump `image: postgres:<newer>` in the yaml.
* `ERROR: dump is only N bytes` → dump failed upstream (auth/network);
  read the lines above it, the DB was NOT touched, nothing uploaded.
* File backup (2:00/2:30) and DB dump (2:30/3:30…) are different points in
  time — normal for dump-based DR; attachments are UUID-keyed so a few
  minutes' skew is harmless.
