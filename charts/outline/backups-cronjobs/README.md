# Outline PVC Backup — `backups-cronjobs/` (live production method)

This folder holds the **actually-running** backups for Outline in the `docs`
namespace. The Helm-chart CronJob under `templates/` is commented out /
`backup.enabled: false` — it is **not** what runs in prod.

## What runs in the cluster

| Object | Name (`-n docs`) | Schedule | Purpose |
|---|---|---|---|
| CronJob | `outline-backup-daily` | `0 2 * * *` (2 AM daily) | → `daily/`, keep 7 days |
| CronJob | `outline-backup-monthly` | `0 3 1 * *` (1st, 3 AM) | → `monthly/`, keep 365 days |
| CronJob | `outline-backup-yearly` | `0 4 1 1 *` (Jan 1st, 4 AM) | → `yearly/`, keep 1095 days (3y) |
| Secret | `minio-backup-secret` | — | MinIO creds (`access-key`, `secret-key`) |
| ConfigMap | `outline-backup-script` | — | `backup-script.sh`, shared by all three |

Why 3 CronJobs instead of 1: independent schedules + independent retention +
failure isolation (a monthly failure never blocks daily), same pattern as
before, easy to read. Schedules are staggered and each uses
`concurrencyPolicy: Forbid` so two tars never run at once.

Job pod spec (same for all three, only `BACKUP_PREFIX`/`RETENTION_DAYS` differ):

* `image: alpine:latest`, `command: ["/bin/sh", "/scripts/backup-script.sh"]`
* `outline-outline-pvc -> /outline-data:readOnly` (same data the
  `outline-outline` Deployment serves from `/var/lib/outline/data`)
* `outline-backup-script (ConfigMap) -> /scripts`, `emptyDir -> /backup`
* env: `MINIO_ENDPOINT=https://minio.ldc.opstree.dev:9000`,
  `MINIO_BUCKET=outline-pvc-backup`, creds from the Secret

Each run: `apk add curl tar` → download `mc` → `mc alias set` →
`tar -czf /backup/outline_<ts>.tar.gz -C /outline-data .` →
`mc cp` to `outline-pvc-backup/<daily|monthly|yearly>/` →
`mc rm --older-than <7|365|1095>d` prunes that prefix → remove local tarball.

Bucket layout (`outline-pvc-backup`):

```text
daily/outline_20260921_093248.tar.gz     (7-day retention)
monthly/outline_20260921_094838.tar.gz   (365-day retention)
yearly/outline_20260921_095030.tar.gz    (1095-day retention)
```

## Re-run / redeploy (safe, idempotent)

```bash
cd charts/outline/backups-cronjobs

# 1. Put real creds in deploy-backup-cronjob.sh (MINIO_ACCESS_KEY / MINIO_SECRET_KEY),
#    and in outline-backup-cronjob.yaml Secret stringData if applying the file directly.
# 2. Deploy (creates/updates 3 CronJobs + Secret + ConfigMap):
./deploy-backup-cronjob.sh
#    or, without the script:
kubectl apply -f outline-backup-cronjob.yaml

# 3. Verify:
kubectl get cronjob -n docs   # expect daily/monthly/yearly
kubectl get jobs -n docs --sort-by=.metadata.creationTimestamp | tail -5

# 4. Trigger a manual backup right now, per tier (does NOT disturb schedules):
kubectl create job outline-backup-daily-manual-$(date +%s) --from=cronjob/outline-backup-daily -n docs
kubectl create job outline-backup-monthly-manual-$(date +%s) --from=cronjob/outline-backup-monthly -n docs
kubectl create job outline-backup-yearly-manual-$(date +%s) --from=cronjob/outline-backup-yearly -n docs

# 5. Watch it (filter by tier):
kubectl logs -n docs -l app=outline-backup,tier=daily --tail=100 -f
#    success ends with "Backup completed successfully!"

# 6. Confirm the object landed in MinIO:
mc alias set minio-backup https://minio.ldc.opstree.dev:9000 <KEY> <SECRET> --api S3v4
mc ls minio-backup/outline-pvc-backup/daily/ | tail -5
mc ls minio-backup/outline-pvc-backup/monthly/ | tail -5
mc ls minio-backup/outline-pvc-backup/yearly/ | tail -5
```

## Restore (PVC deleted / data loss)

File restores live next door in `../recovery-pvc/` — runbook + Job + guided
script (`./restore.sh <BACKUP_KEY>`). DB restores are in
`../db-backups-cronjobs/` (`restore-existing-db.md` for accidental deletes,
`restore-deleted-db.md` for full rebuilds).

## Troubleshooting

* `BackoffLimitExceeded` in ~6 min + no upload → check the `mc` download step
  first (`kubectl logs -l app=outline-backup` should show `curl` / `mc --version`).
* `410 Gone` from `dl.min.io` → the download path changed again; check
  https://dl.minio.io/aistor/mc/release/linux-amd64/ for the current layout.
* `ImagePullBackOff` on `alpine:latest` → registry/network issue, unrelated to
  this script; consider pinning the image digest.
* Retention is `mc rm --force --recursive --older-than Nd` per prefix. If old
  files pile up again, check the `BACKUP_PREFIX`/`RETENTION_DAYS` env on the
  CronJob and the cleanup lines in `backup-script.sh`.
* Old single-tier CronJob `outline-backup` no longer exists; tier CronJobs are
  `outline-backup-daily|monthly|yearly`. Old manual jobs named
  `outline-backup-manual-*` are pre-tier leftovers, safe to delete.
