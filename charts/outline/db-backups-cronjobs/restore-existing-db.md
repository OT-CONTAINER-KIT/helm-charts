# DB Recovery Method 1 — database is ALIVE, data was deleted by mistake
# (e.g. someone deleted important pages in the Outline UI)
#
# Approach: SURGICAL row recovery. The dump is plain SQL, so we pull out just
# the deleted rows on your workstation and re-insert them through a throwaway
# pod. No superuser needed, no downtime for the data that still exists.
#
# ⚠️  Read first:
# - Scale Outline to 0 first (stops new writes while you work).
# - This re-inserts rows deleted AFTER the backup was taken. It does NOT undo
#   anything else, and it cannot resurrect rows deleted BEFORE the backup.
# - Foreign keys: re-insert parents before children
#   (teams/users/collections before documents/attachments). If many tables are
#   affected or you're unsure of the order, skip to Method 2 (full rewind).
# - Full overwrite from inside the cluster is NOT offered here on purpose:
#   it needs superuser (dropdb/terminating backends); that path lives in
#   restore-deleted-db.md (run it even when the DB "exists" but must be rewound).

# ── Step 0. Freeze writers ──────────────────────────────────────────────
kubectl scale deployment outline-outline --replicas=0 -n docs
kubectl wait --for=delete pod -l app=outline -n docs --timeout=180s

# ── Step 1. Fetch + unpack the newest daily dump (workstation) ─────────
mc alias set minio-backup https://minio.ldc.opstree.dev:9000 <KEY> <SECRET> --api S3v4
mc ls --recursive minio-backup/outline-db-backup/daily/ | tail -5
mc cp minio-backup/outline-db-backup/daily/outline-db_<ts>.sql.gz /tmp/restore.sql.gz
gunzip -c /tmp/restore.sql.gz > /tmp/restore.sql

# ── Step 2. Find the deleted rows in the dump ───────────────────────────
# Page titles live in the documents table — search by title text:
grep -i "exact words from the deleted page title" /tmp/restore.sql | head
# Note the UUID (first column). Repeat for every deleted page/row.

# ── Step 3. Build a chunk file with ONLY those rows ────────────────────
# Replace TABLE as needed (documents, collections, attachments, users...)
# and put each deleted UUID in place of <DELETED_UUID>.
TABLE=documents
awk -v t="$TABLE" '
  $0 ~ "^COPY public\\."t" \\(" {hdr=$0; rows=""; cap=1; next}
  cap && $0 == "\\." { print hdr; printf "%s", rows; print "\\."; cap=0; next }
  cap { if ($0 ~ /<DELETED_UUID_1>|<DELETED_UUID_2>/) rows=rows $0 "\n" }
' /tmp/restore.sql > /tmp/chunk.sql
# Sanity: chunk should be COPY header + your rows + \. footer:
cat /tmp/chunk.sql | head -n 5
# Repeat per table, parents before children (users/collections → documents).

# ── Step 4. Throwaway psql pod (app credentials, no superuser) ─────────
kubectl apply -n docs -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pg-helper
spec:
  containers:
    - name: psql
      image: postgres:17
      command: ["sleep", "3600"]
      env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: outline-postgres-external-secret
              key: DATABASE_URL
  restartPolicy: Never
EOF
kubectl wait --for=condition=Ready pod/pg-helper -n docs --timeout=120s

# ── Step 5. Re-insert (COPY FROM stdin streams through exec) ────────────
# NOTE the quoting: "$DATABASE_URL" must expand INSIDE the pod, not locally.
kubectl exec -i -n docs pg-helper -- sh -c 'psql "$DATABASE_URL" -v ON_ERROR_STOP=1' < /tmp/chunk.sql
# "COPY 3" (or your row count) = success. Duplicate-key errors mean the row
# already exists — harmless, but double-check you targeted the right UUIDs.

# ── Step 6. Verify, clean up, back online ───────────────────────────────
kubectl exec -n docs pg-helper -- sh -c 'psql "$DATABASE_URL" -tAc "SELECT COUNT(*) FROM documents;"'
kubectl delete pod pg-helper -n docs
rm -f /tmp/restore.sql /tmp/restore.sql.gz /tmp/chunk.sql
kubectl scale deployment outline-outline --replicas=2 -n docs
kubectl rollout status deployment/outline-outline -n docs
# Open the pages in the UI to confirm.
