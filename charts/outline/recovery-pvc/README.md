# Outline PVC Disaster Recovery — `recovery-pvc/`

For the day someone deletes `outline-outline-pvc` (or it otherwise vanishes)
in the `docs` namespace. File-data recovery from MinIO. **DB recovery is
separate** — see `../db-replace.sh` + `../DR/`.

## Good news first

Your PV uses `persistentVolumeReclaimPolicy: Retain`, so deleting the PVC does
**not** delete the Longhorn volume. The PV flips to `Released` with your data
still on it. Two possible outcomes:

| Case | What you see | Path |
|---|---|---|
| A. PV `Released`, data intact | `kubectl get pv` shows old PV `Released` | Rebind it (fast, no download) — §1 |
| B. PV/volume truly gone | No `Released` PV | Rebuild from MinIO backup — §2 |

In both cases start with §0.

## §0. Freeze writers (both cases)

```bash
kubectl scale deployment outline-outline --replicas=0 -n docs
kubectl wait --for=delete pod -l app=outline -n docs --timeout=180s
```

## §1. Case A — re-attach the Retained PV (preferred, minutes)

```bash
# 1. Confirm the old PV is Released (not Bound, not Lost):
kubectl get pv | grep -i outline
# expect: pvc-xxxx  5Gi  RWX  Retain  Released  docs/outline-outline-pvc ...

# 2. Clear the stale claim reference so it becomes Available:
PV=<the-pv-name-from-above>
kubectl patch pv $PV --type=json -p='[{"op":"remove","path":"/spec/claimRef"}]'

# 3. Re-create the PVC (same name/class/size → rebinds to that PV):
kubectl apply -f recovery/pvc.yaml
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/outline-outline-pvc -n docs --timeout=180s

# 4. Back online:
kubectl scale deployment outline-outline --replicas=2 -n docs
kubectl rollout status deployment/outline-outline -n docs

# 5. Verify (expect ~1280 files, public/ + uploads/):
POD=$(kubectl get pod -n docs -l app=outline -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n docs "$POD" -- ls -la /var/lib/outline/data
kubectl exec -n docs "$POD" -- find /var/lib/outline/data -type f | wc -l
```

## §2. Case B — rebuild from MinIO (or `restore.sh`, which automates §0–§2)

Prerequisites: namespace `docs` and `minio-backup-secret` must exist. If the
whole namespace was wiped, re-apply `../backups-cronjobs/outline-backup-cronjob.yaml`
first (it carries the Secret), then continue here.

```bash
# 1. Pick a backup (newest daily is usually right):
mc alias set minio-backup https://minio.ldc.opstree.dev:9000 <KEY> <SECRET> --api S3v4
mc ls --recursive minio-backup/outline-pvc-backup/
# e.g. daily/outline_20260921_093248.tar.gz

# 2a. Guided (recommended):
./recovery/restore.sh daily/outline_20260921_093248.tar.gz

# 2b. Manual equivalent:
kubectl apply -f recovery/pvc.yaml
# edit BACKUP_KEY in recovery-pvc/restore-job.yaml, then:
kubectl apply -f recovery/restore-job.yaml
kubectl wait --for=condition=complete job/outline-restore -n docs --timeout=1800s
kubectl logs -n docs -l app=outline-restore --tail=25
kubectl scale deployment outline-outline --replicas=2 -n docs
kubectl rollout status deployment/outline-outline -n docs
```

The restore Job wipes the volume (except `lost+found`), extracts the tarball,
`chown -R 1001:1001` (Outline's nodejs user), and prints the restored file
count — compare it with the number from §1 step 5.

## Files

| File | Role |
|---|---|
| `pvc.yaml` | Standalone copy of `../templates/outline-pvc.yaml` (5Gi, RWX, Longhorn class) |
| `restore-job.yaml` | ConfigMap (restore script) + Job; set `BACKUP_KEY` before applying |
| `restore.sh` | Automates §0+§1-rebind-check+§2; usage: `./restore.sh <BACKUP_KEY>` |
| `README.md` | This runbook |

## Notes

* Restoring files is only half the story if the database is also gone or
  out of sync — attachments are keyed by UUIDs the DB references. After a
  **full** disaster, restore Postgres first — from your own MinIO dumps:
  DB alive but rows deleted → `../db-backups-cronjobs/restore-existing-db.md`;
  DB gone or full rewind → `../db-backups-cronjobs/restore-deleted-db.md`
  (legacy server-side-only flow: `../db-replace.sh`) — then files.
* The restore Job uses the same fixed `mc` download URL as the backup
  (`.../aistor/mc/...`, not the retired `.../client/mc/...`).
* Clean up after yourself: `kubectl delete job outline-restore -n docs` once
  verified (keeps `kubectl get jobs` tidy).
