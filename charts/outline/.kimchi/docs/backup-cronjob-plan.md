# Plan: Add PVC-to-MinIO Backup CronJob to Outline Helm Chart

## Context
- Helm chart for Outline Wiki at `/home/vishaltyagi/Desktop/helm-charts/charts/outline`
- PVC `outline-data` is mounted at `/var/lib/outline/data` with `ReadWriteMany` access mode
- Internal MinIO at `192.168.8.18`, bucket `docs` already created
- Need a Kubernetes CronJob to periodically back up the PVC contents to MinIO

## Chunk 1: Helm Values + CronJob Template + Secret Template

### Files
1. `values.yaml` — add `backup:` map
2. `templates/outline-backup-cronjob.yaml` — new
3. `templates/outline-backup-secret.yaml` — new

### `values.yaml` additions
```yaml
backup:
  enabled: true
  schedule: "0 2 * * *"   # daily at 2 AM
  suspend: false
  image:
    repository: minio/mc
    tag: latest
    pullPolicy: IfNotPresent
  retention:
    days: 14
  minio:
    endpoint: "http://192.168.8.18:9000"
    bucket: "docs"
    pathPrefix: "outline-backups"
    existingSecret: ""
    accessKeyKey: "accessKey"
    secretKeyKey: "secretKey"
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "256Mi"
```

### `templates/outline-backup-cronjob.yaml`
- `apiVersion: batch/v1`
- `kind: CronJob`
- `metadata.name: {{ .Release.Name }}-outline-backup`
- `spec.schedule: {{ .Values.backup.schedule }}`
- `spec.suspend: {{ .Values.backup.suspend }}`
- `spec.jobTemplate.spec.template.spec.securityContext` matching app (runAsUser: 1001, runAsGroup: 1001, fsGroup: 1001, runAsNonRoot: true)
- Init-style container or single container with a shell script:
  1. `mc alias set minio $MINIO_ENDPOINT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY`
  2. `tar czf /tmp/outline-backup-$(date +%Y%m%d-%H%M%S).tgz -C {{ .Values.outline.fileStorageLocalRootDir }} .`
  3. `mc cp /tmp/outline-backup-*.tgz minio/$BUCKET/$PATH_PREFIX/`
  4. `mc rm --force --recursive --older-than ${RETENTION}d minio/$BUCKET/$PATH_PREFIX/`
- Mount the same PVC (`{{ .Release.Name }}-outline-pvc`) at `{{ .Values.outline.fileStorageLocalRootDir }}`
- Pass env vars from secret for MinIO credentials
- Pass env vars for endpoint, bucket, pathPrefix, retention
- Set `restartPolicy: OnFailure`
- Set `activeDeadlineSeconds: 3600`
- Set `successfulJobsHistoryLimit: 3`, `failedJobsHistoryLimit: 3`
- Set `concurrencyPolicy: Forbid`

### `templates/outline-backup-secret.yaml`
- `kind: Secret`
- Only created if `.Values.backup.enabled` is true AND `.Values.backup.minio.existingSecret` is empty
- `metadata.name: {{ .Release.Name }}-outline-backup-secret`
- Placeholder `data:` fields for `accessKey` and `secretKey` encoded in base64 (use `""` as placeholder, i.e. `Cg==`)
- Include a Helm `fail` or `required` message so user knows to fill values or use existingSecret

### Acceptance Criteria
- `helm template .` renders without error
- CronJob manifest mounts the same PVC at the same path as the deployment
- CronJob uses `mc` to push a gzip tarball to the configured MinIO bucket
- CronJob removes backups older than configured retention days
- If `backup.minio.existingSecret` is set, the chart does not create its own secret
- The backup container runs as non-root user 1001 matching the app's security context
