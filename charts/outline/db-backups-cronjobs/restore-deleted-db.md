# DB Recovery Method 2 — database is GONE (or must be fully rewound)
#
# Run on the Postgres server host (192.168.8.39) as root / postgres superuser.
# Same staging → verify → swap procedure as ../db-replace.sh, except the dump
# comes from YOUR MinIO bucket instead of the DBA — so it works with zero DBA
# involvement. Use this when:
# - the `outline` database was dropped / corrupted beyond surgical repair, or
# - the DB exists but needs a FULL rewind to backup time (Method 1 can't do
#   overwrites — it needs the superuser powers used here).
#
# ⚠️  Full rewind DESTROYS everything written after the backup. Confirm the
# timestamp before you start.

# ── Step 0. Freeze writers (workstation) ───────────────────────────────
kubectl scale deployment outline-outline --replicas=0 -n docs
kubectl wait --for=delete pod -l app=outline -n docs --timeout=180s

# ── Steps below run ON THE DB HOST (ssh there first) ───────────────────
cd /tmp   # so sudo -u postgres never tries to chdir into /root

# ── Step 1. Fetch the dump from MinIO ──────────────────────────────────
# Install mc if missing (NOTE: old /client/mc URL is retired -> 410 Gone):
curl -fsSL -o /tmp/mc https://dl.min.io/aistor/mc/release/linux-amd64/mc
chmod +x /tmp/mc && sudo mv /tmp/mc /usr/local/bin/mc
mc alias set minio-backup https://minio.ldc.opstree.dev:9000 <KEY> <SECRET> --api S3v4
mc ls --recursive minio-backup/outline-db-backup/
# pick daily (newest), monthly, or yearly:
mc cp minio-backup/outline-db-backup/daily/outline-db_<ts>.sql.gz /tmp/restore.sql.gz
gunzip -c /tmp/restore.sql.gz > /tmp/outline_migration.sql
ls -lh /tmp/outline_migration.sql   # sanity: expect tens of MB, not KB

# ── Step 2. Safety backup of whatever is (or isn't) there ──────────────
DATE=$(date +%Y%m%d-%H%M%S)
sudo -u postgres pg_dump -Fc outline > "/tmp/outline-current-backup-${DATE}.dump" || \
  echo "no live DB to back up — continuing with empty restore"

# ── Step 3. (Only if role/DB were dropped) recreate role + empty DB ────
# Get the app password WITHOUT printing it: decode DATABASE_URL from the
# cluster secret into shell vars (run on a machine with kubectl access):
#   eval $(kubectl get secret outline-postgres-external-secret -n docs \
#     -o jsonpath='{.data.DATABASE_URL}' | base64 -d | \
#     python3 -c "import sys,urllib.parse; u=urllib.parse.urlparse(sys.stdin.read()); print(f\"DBPASS={u.password} DBUSER={u.username}\")")
# Then on the DB host:
#   sudo -u postgres psql -c "DO \$\$ BEGIN IF NOT EXISTS \
#     (SELECT FROM pg_roles WHERE rolname = '$DBUSER') THEN \
#     CREATE ROLE \"$DBUSER\" LOGIN PASSWORD '$DBPASS'; END IF; END \$\$;"
#   sudo -u postgres psql -c "SELECT 1 FROM pg_database WHERE datname='outline'" | grep -q 1 || \
#     sudo -u postgres createdb -O "$DBUSER" outline

# ── Step 4. Restore into staging (never touch live first) ──────────────
sudo -u postgres psql -c "DROP DATABASE IF EXISTS outline_staging;"
sudo -u postgres psql -c "CREATE DATABASE outline_staging OWNER \"outline-db-user\";"
sudo -u postgres psql -d outline_staging -f /tmp/outline_migration.sql

# ── Step 5. Grants (PG15+ locks down public schema — this covers it) ───
sudo -u postgres psql -d outline_staging -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"outline-db-user\";"
sudo -u postgres psql -d outline_staging -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO \"outline-db-user\";"
sudo -u postgres psql -d outline_staging -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO \"outline-db-user\";"
sudo -u postgres psql -d outline_staging -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO \"outline-db-user\";"

# ── Step 6. Swap staging into live (one session, nothing reconnects) ───
sudo -u postgres psql -d postgres <<EOF
  SELECT pg_terminate_backend(pid)
  FROM pg_stat_activity
  WHERE datname IN ('outline', 'outline_staging')
    AND pid <> pg_backend_pid();

  ALTER DATABASE outline RENAME TO outline_old;
  ALTER DATABASE outline_staging RENAME TO outline;
EOF

# ── Step 7. Verify counts, then drop the old DB ────────────────────────
sudo -u postgres psql -d outline -c "SELECT COUNT(*) AS documents FROM documents;"
sudo -u postgres psql -d outline -c "SELECT COUNT(*) AS users FROM users;"
sudo -u postgres psql -d outline -c "SELECT COUNT(*) AS teams FROM teams;"
# compare with pre-incident numbers if you have them, then:
sudo -u postgres psql -d postgres -c "DROP DATABASE IF EXISTS outline_old;"

# Post-major-upgrade (e.g. restored onto PG 18): REINDEX text indexes if PG
# warns about collation version mismatch, then ANALYZE.

# ── Step 8. Back online (workstation) ──────────────────────────────────
kubectl scale deployment outline-outline --replicas=2 -n docs
kubectl rollout status deployment/outline-outline -n docs
