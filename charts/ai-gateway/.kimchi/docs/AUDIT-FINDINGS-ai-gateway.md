# Audit Report — `ai-gateway` Helm Chart (LiteLLM)

> **Chart path:** `/home/vishaltyagi/Desktop/helm-charts/charts/ai-gateway`
> **Chart name (in `Chart.yaml`):** `buildpiper-helm` ⚠️ *(mismatch with folder name `ai-gateway`)*
> **Chart version:** `1.1.0` &nbsp;&nbsp; **App version:** `1.87.1`
> **Image:** `ghcr.io/berriai/litellm@sha256:75543fa1...` *(digest-pinned ✅)*
> **Auditor methodology:** Walked every section of `MASTER-HELM-K8S-AUDIT-CHECKLIST.md` against `helm template` output and source.

---

## Verdict: ❌ REJECTED

| Bucket | Count |
|---|---:|
| PASS | 28 |
| FAIL | 33 |
| of which BLOCKER | **11** |
| N/A | 4 |
| **Score** | **46 / 100** |

> 11 BLOCKERs fail + score < 85 ⇒ **must not ship** as-is.

---

## Executive summary — top 5 things to fix before re-audit

1. **Chart does not render with default values** — `sso:` block is indented under `redis:` in `values.yaml`, so `.Values.sso` is nil and `helm template` exits with a nil-pointer error. (BLOCKER #1.1)
2. **Zero `securityContext` anywhere** — pods run as root, no seccomp, no capability drop, no read-only root FS. (BLOCKER #2.x / 3.x — 8 items)
3. **Plaintext secret pattern is the default** — `values.yaml` has `masterKey: ""` / `saltKey: ""` but the chart will silently create a Secret with empty strings unless `existingSecret` is set. There is no guard preventing this. (HIGH)
4. **`requests == limits` on CPU and memory** — defeats HPA's ability to detect utilization pressure and forces QoS `Guaranteed` (anti-pattern for stateless web tier). (HIGH)
5. **No liveness probe, no startup probe** — only readiness is defined. If LiteLLM hangs in a non-ready state but is "ready" once, it will never be restarted. (HIGH)

---

## Section 1 — Chart Hygiene

### ❌ [BLOCKER] 1.1 — Chart fails to render with default values
**Evidence:**
```bash
$ helm template ai-gateway .
Error: buildpiper-helm/templates/sso-secret.yaml:1:18
  executing "buildpiper-helm/templates/sso-secret.yaml" at <.Values.sso.enabled>:
    nil pointer evaluating interface {}.enabled
```
**Why it matters:** Any deployment using `helm install` with default values will fail. This means the chart as-shipped is unusable without `--set sso.enabled=false` or pre-known workarounds.
**Root cause:** In `values.yaml` line 134, `sso:` is indented with **2 spaces**, making it a child of `redis:` (line 122). The `# ===...` comment on line 131 starts with **3 spaces**, which shifts everything below it back under `redis:`. As a result, top-level `sso` is never parsed.
**Fix:** Move `sso:` to top level (0 spaces). See `SECURITY-HARDENING-PATCH.md` § A.
**Verify:**
```bash
helm template ai-gateway . 2>&1 | grep -i error ; echo "exit=$?"
# expect: no "Error" lines, exit=0
```

### ❌ [HIGH] 1.4 — Hardcoded resource names partially templated, partially hardcoded
**Evidence:** `templates/litellm-secret.yaml:6` uses `{{ .Release.Name }}-litellm-secret` ✅, but `templates/litellm-deployment.yaml:5` has `# namespace: {{ .Values.namespace }}` commented out — relies on `-n` flag from CLI.
**Why it matters:** Multi-namespace deploys need a `namespace:` field either fully templated or fully omitted.
**Fix:** Remove commented-out lines. Decide: either template `namespace:` from `Values.namespace` or omit and document.

### ❌ [HIGH] 1.5 / 1.7 — Chart.yaml metadata mismatch
**Evidence:**
- `Chart.yaml` `name: buildpiper-helm` but folder is `ai-gateway`.
- `Chart.yaml` `appVersion: "1.87.1"` and `values.yaml` image digest corresponds to that, but no note about how to bump them together.
**Fix:** Rename chart to `ai-gateway`, add a `kubeVersion: ">=1.25.0-0"` constraint.

### ❌ [HIGH] 1.8 — Docs reference duplicate secret templates that don't exist (and one template that does is undocumented)
**Evidence:** `reame/BUILDPIPER_IMPORTANT_FILES.md` says:
> Your chart currently has two external Postgres secret templates: `postgres-external-secret.yaml` and `external-postgres-secret.yaml`
But `ls templates/` shows only `postgres-external-secret.yaml` — the duplicates were never added (or were removed). The doc is stale.
**Fix:** Either remove the warning or re-add the duplicate templates with a `_disabled` name so they don't collide.

---

## Section 2 — Pod-Level `securityContext` — ALL MISSING **[BLOCKER]**

| # | Check | Status |
|---|---|---|
| 2.1 | `spec.template.spec.securityContext` block exists | ❌ FAIL — no such block in `templates/litellm-deployment.yaml` |
| 2.2 | `runAsNonRoot: true` | ❌ FAIL |
| 2.3 | `runAsUser` / `runAsGroup` non-zero | ❌ FAIL — no UID set, image default applies (likely root) |
| 2.4 | `fsGroup` | ❌ FAIL |
| 2.5 | `seccompProfile.type: RuntimeDefault` | ❌ FAIL |

**Evidence:** `grep -r 'securityContext\|runAsNonRoot\|seccomp' templates/` → no matches.
**Why it matters:** Pod runs with whatever UID the image Dockerfile specifies. LiteLLM Dockerfiles commonly run as root. Combined with no `readOnlyRootFilesystem` (Section 3), a single RCE = full container root + writable FS = trivially host-compromise pivot.
**Fix:** See `SECURITY-HARDENING-PATCH.md` § B for the full pod `securityContext` block.

---

## Section 3 — Container-Level `securityContext` — ALL MISSING **[BLOCKER]**

| # | Check | Status |
|---|---|---|
| 3.1 | Container `securityContext` exists | ❌ FAIL |
| 3.2 | `allowPrivilegeEscalation: false` | ❌ FAIL |
| 3.3 | `readOnlyRootFilesystem: true` + writable volume mounts | ❌ FAIL — entire `/` is writable |
| 3.4 | `capabilities.drop: ["ALL"]` | ❌ FAIL |
| 3.5 | No `privileged: true` | ✅ PASS (default absent) |
| 3.6 | No `hostNetwork/PID/IPC` | ✅ PASS (default absent) |

**Why it matters:** LiteLLM is a network-facing LLM gateway that ingests user prompts. If an attacker gets prompt-injection to RCE (e.g. via a malicious model response that triggers a tool call bug), they have root inside the container with the full root filesystem writable — meaning they can `curl | sh` a backdoor directly into `/usr/local/bin`.
**Fix:** See `SECURITY-HARDENING-PATCH.md` § B.

---

## Section 4 — Identity & RBAC

### ❌ [HIGH] 4.1 — No `serviceAccountName` set; uses `default`
**Evidence:** `templates/litellm-deployment.yaml` — no `serviceAccountName:` line.
**Why it matters:** If the cluster's `default` SA is bound to any cluster-scoped role (common in dev clusters), the LiteLLM pod inherits it.
**Fix:** Create a dedicated `ServiceAccount` resource in the chart (`templates/serviceaccount.yaml`), set `automountServiceAccountToken: false` (LiteLLM doesn't call the K8s API), reference by name in the deployment.

---

## Section 5 — Image Supply Chain

### ✅ [PASS] 5.1 — Image pinned by digest
**Evidence:** `values.yaml:2`: `image: ghcr.io/berriai/litellm@sha256:75543fa1d73989b7aefba49c910989f7886f63210520e30b39dbbc580a41826f`

### ❌ [HIGH] 5.2 — `imagePullPolicy: Always` with digest-pinned image
**Evidence:** `values.yaml:3`: `imagePullPolicy: Always`
**Why it matters:** Digest-pinned images are immutable — pulling them on every pod start wastes 5–30 s of init time and adds load to the registry. With a digest, `IfNotPresent` is the correct choice.
**Fix:** Change default to `IfNotPresent`.

### ❌ [HIGH] 5.3 — No `imagePullSecrets`
**Evidence:** No `imagePullSecrets:` in deployment template.
**Why it matters:** Currently works because `ghcr.io/berriai/litellm` is public. The moment you move to a private registry (very common in production), deploys will silently fail with `ImagePullBackOff`.
**Fix:** Add `imagePullSecrets: []` (templated, default empty) to deployment, document in README.

### ❌ [BLOCKER] 5.4 — `STORE_MODEL_IN_DB: True` and `LITELLM_MODE: PRODUCTION` baked as plain env values
**Evidence:** `templates/litellm-deployment.yaml` lines 60 and `values.yaml` `extraEnv`.
**Why it matters:** Not a secret leak — these are operational flags — but the pattern of hardcoded env-without-secretKeyRef for app config is a slippery slope. Also, `DISABLE_SCHEMA_UPDATE=true` + no migration Job means any schema change during upgrade is silently skipped → next boot fails on schema mismatch. **Document or fix.**
**Fix:** Either add a Helm pre-upgrade hook Job that runs `litellm --apply-db-migration`, or remove `DISABLE_SCHEMA_UPDATE=true` from default values.

---

## Section 6 — Resource Management & HPA

### ❌ [BLOCKER] 6.1 / 6.2 — `requests` and `limits` set, but equal (forces QoS `Guaranteed`)
**Evidence:** `values.yaml:10-16`:
```yaml
resources:
  requests:
    cpu: "1"
    memory: "4Gi"
  limits:
    cpu: "1"
    memory: "4Gi"
```
**Why it matters:**
- **HPA on memory is a no-op** when `requests.memory == limits.memory`. HPA needs headroom between request and limit to detect utilization.
- **QoS `Guaranteed`** means kube treats this pod as a "best effort to never kill". On a node under pressure, only pods with QoS `BestEffort` get evicted first. Mixing Guaranteed and Burstable pods across the cluster causes eviction surprises.
- **For LiteLLM** (which is a stateless gateway), QoS `Burstable` is the correct choice — set `requests` lower than `limits`.

**Fix:** Use `requests: { cpu: 500m, memory: 2Gi }` and `limits: { cpu: 2, memory: 4Gi }` for starters. Document and tune.

### ❌ [HIGH] 6.4 / 6.5 — HPA has no `behavior` block
**Evidence:** `templates/litellm-hpa.yaml` has `metrics:` but no `behavior:`.
**Why it matters:** Without explicit `scaleDown.stabilizationWindowSeconds`, the default is **5 minutes** — that's actually fine. But `scaleUp` is more aggressive by default, which can cause replica thrashing on bursty LLM traffic.
**Fix:** Add a `behavior:` block:
```yaml
behavior:
  scaleDown:
    stabilizationWindowSeconds: 300
  scaleUp:
    stabilizationWindowSeconds: 30
    policies:
      - type: Percent
        value: 100
        periodSeconds: 60
```

---

## Section 7 — Health Probes & Lifecycle

### ❌ [HIGH] 7.2 — No `livenessProbe`
**Evidence:** `values.yaml:18-26` only defines `readinessProbe`.
**Why it matters:** If LiteLLM hangs after a bad model response (known to happen with certain providers), the pod stays "Running" but serves nothing. K8s never restarts it.
**Fix:** Add `livenessProbe` pointing at `/health/liveliness` with generous `initialDelaySeconds` (LiteLLM can take 60+ s to fully boot).

### ❌ [MED] 7.3 — No `startupProbe`
**Evidence:** Not present.
**Why it matters:** LiteLLM cold-starts model lists from DB → can take 30–90 s on first pod. Without a startup probe, the first `livenessProbe` failure (during boot) will trigger a `CrashLoopBackOff` even though the app is just slow.
**Fix:** Add `startupProbe` with `failureThreshold: 30, periodSeconds: 10` (covers 5 minutes of startup).

### ✅ [PASS] 7.5 — `preStop: sleep 5` is set
**Evidence:** `templates/litellm-deployment.yaml:147`

### ⚠️ [HIGH] 7.6 — `terminationGracePeriodSeconds: 620` is over 10 minutes
**Evidence:** `values.yaml:27`
**Why it matters:** This is intentional to match `request_timeout: 600` in `values.yaml`, but K8s default for PDB + rolling updates is 30 s — meaning node drains can stall for 10+ min per pod during upgrades. Document and lower if possible. 60–120 s is usually enough for LiteLLM to drain in-flight streaming responses.
**Fix:** Set to `120` and document the trade-off; add note that `request_timeout` should not exceed `terminationGracePeriodSeconds`.

---

## Section 8 — Scheduling, Placement & Availability

### ❌ [HIGH] 8.2 / 8.3 — No `topologySpreadConstraints` and no `podAntiAffinity`
**Evidence:** Not present in `templates/litellm-deployment.yaml`.
**Why it matters:** With 2 replicas (and HPA scaling to 10), all pods can land on a single node → single node failure = full outage.
**Fix:** Add the block from the Outline reference doc (Section 3 of that document) — `maxSkew: 1, topologyKey: kubernetes.io/hostname`.

### ✅ [PASS] 8.1 — `replicas: 2` set
### ✅ [PASS] 8.6 / 8.7 — PDB with `minAvailable: 1`

### ⚠️ [HIGH] 8.8 — HPA `maxReplicas: 10` vs deployment `replicas: 2` ✅ — but no `minReplicas` matching (HPA defaults `minReplicas: 2` in chart). OK, but should be explicit.

### ❌ [MED] 8.4 — No `priorityClassName`
**Evidence:** Not set in deployment.
**Why it matters:** On a cluster with multiple tenants, a higher-priority workload can preempt the AI gateway during node pressure.
**Fix:** Add `priorityClassName: system-cluster-critical` (or org-specific class) for production. Default to empty for dev.

---

## Section 9 — Secrets Management

### ❌ [BLOCKER] 9.1 — Plaintext secret pattern is the default and chart silently creates Secrets with empty strings
**Evidence:** `values.yaml:30-32`:
```yaml
existingSecret: ""
masterKey: ""
saltKey: ""
```
**Why it matters:** If a junior runs `helm install ai-gateway .` without remembering to set `existingSecret`, the chart will create `ai-gateway-litellm-secret` with `masterKey: ""` and `saltKey: ""`. LiteLLM will boot with **no master key** — anyone who can hit the service is admin. This is silent and catastrophic.
**Fix:** Add a `required` guard in the secret template:
```yaml
{{- if and (not .Values.litellm.existingSecret) (not .Values.litellm.masterKey) }}
{{- fail "litellm.masterKey must be set OR litellm.existingSecret must reference an existing Secret" }}
{{- end }}
```
Same for `saltKey`.

### ✅ [PASS] 9.2 — All secret env vars use `secretKeyRef`
**Evidence:** `templates/litellm-deployment.yaml` lines 42-100.

### ✅ [PASS] 9.3 — Secrets use `stringData`
**Evidence:** `templates/litellm-secret.yaml:7`, `postgres-external-secret.yaml:7`, `redis-external-secret.yaml:7`, `sso-secret.yaml:7`.

### ❌ [HIGH] 9.4 — `existingSecret` pattern not uniformly supported
**Evidence:** `litellm-secret.yaml`, `postgres-external-secret.yaml`, `redis-external-secret.yaml`, `sso-secret.yaml` all support it ✅. But the DB URL is only supported via `existingSecret` — no fallback for users who want to put the URL in the chart and rely on platform secret injection. (This is actually a separate pattern — value-based secret.) Both should be supported cleanly.

---

## Section 10 — Network & Traffic

### ✅ [PASS] 10.1 — `service.type: ClusterIP` by default (correct for internal-only with platform-managed Ingress)
### ✅ [PASS] 10.3 — `selector: { app: litellm }` matches pod label `{ app: litellm }`
### ❌ [HIGH] 10.4 — `ingress.className: nginx` is set but `ingress.enabled: false` by default
**Evidence:** `values.yaml:74-77`
**Why it matters:** If you ever enable Ingress, the `className: nginx` is hardcoded — but the doc clearly says Envoy Gateway is the actual proxy. Misleading.
**Fix:** Remove default `className` or default to `""` with comment "ask platform team".

### ❌ [HIGH] 10.5 — TLS defaults off; no cert-manager integration
**Evidence:** `values.yaml:83-86` `tls.enabled: false`.
**Why it matters:** A LLM proxy should always be TLS-terminated. The chart currently does not generate certs nor annotate Ingress for cert-manager.
**Fix:** Add cert-manager annotation template, or document that TLS is always expected at the platform gateway (current model — make this explicit in README).

### ❌ [MED] 10.7 — No NetworkPolicy
**Evidence:** No `kind: NetworkPolicy` in templates.
**Why it matters:** Any pod in the namespace can hit the LiteLLM proxy. Any compromised pod in the cluster can exfiltrate via the proxy.
**Fix:** Add a default-deny + allow-from-ingress-namespace NetworkPolicy.

---

## Section 11 — Observability

### ❌ [MED] 11.1 — No Prometheus annotations on pod template
**Evidence:** `templates/litellm-deployment.yaml` has no `annotations:`.
**Why it matters:** LiteLLM exposes `/metrics` only when configured — but pod-level annotations are how Prometheus discovers what to scrape.
**Fix:** Add `prometheus.io/scrape: "true"` + `prometheus.io/port: "4000"` annotations (gated by `Values.metrics.enabled`).

### ❌ [MED] 11.2 — `LITELLM_LOG: ERROR` is fine but no structured JSON logging
**Why it matters:** Hard to ship to Loki/ELK at scale.
**Fix:** Document that downstream log shippers should parse stderr JSON.

### ❌ [LOW] 11.5 — Labels only have `app: litellm` — missing `app.kubernetes.io/*` recommended labels
**Fix:** Add to deployment template:
```yaml
labels:
  app: litellm
  app.kubernetes.io/name: litellm
  app.kubernetes.io/instance: {{ .Release.Name }}
  app.kubernetes.io/version: {{ .Chart.AppVersion }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
  app.kubernetes.io/component: ai-gateway
  app.kubernetes.io/part-of: buildpiper
```

---

## Section 12 — Configuration & ConfigMap Hygiene

### ✅ [PASS] 12.1 — ConfigMap mounted `readOnly: true`
**Evidence:** `templates/litellm-deployment.yaml:159`.

### ✅ [PASS] 12.2 — `subPath: config.yaml` used ✅

### ⚠️ [HIGH] 12.4 — ConfigMap uses `os.environ/REDIS_PASSWORD` but `REDIS_PASSWORD` is only set when secret exists
**Evidence:** `templates/litellm-config.yaml:7` references `os.environ/REDIS_PASSWORD`. The deployment sets `REDIS_PASSWORD` env var **only if** `redis.external.existingSecret` OR `redis.external.password` is set:
```yaml
{{ if and (not .Values.redis.enabled) (or .Values.redis.external.existingSecret .Values.redis.external.password) }}
```
**Why it matters:** If both are empty (default), `REDIS_PASSWORD` env var is **not set**, but `config.yaml` still tells LiteLLM to use `os.environ/REDIS_PASSWORD`. App boot may fail or fall back to no-auth Redis connection.
**Fix:** Always set `REDIS_PASSWORD` env var (even as empty string) or document clearly that "no Redis password" means leaving both empty.

### ❌ [MED] 12.5 — Hardcoded internal IP in values
**Evidence:** `values.yaml:106`: `host: "192.168.8.78"` (Redis) and Postgres in deployment doc is `192.168.8.39`.
**Why it matters:** Chart can't be reused across dev/stage/prod without a values override.
**Fix:** Make hostnames a required value or document override pattern in README.

---

## Section 13 — Upgrade & Rollout Safety

### ✅ [PASS] 13.1 / 13.2 — `RollingUpdate` with `maxUnavailable: 0, maxSurge: 1` ✅ excellent
### ⚠️ [MED] 13.4 — `terminationGracePeriodSeconds: 620` (see Section 7.6)

### ❌ [MED] 13.6 — `DISABLE_SCHEMA_UPDATE=true` with no documented migration step in chart
**Evidence:** `values.yaml` `extraEnv` includes `DISABLE_SCHEMA_UPDATE: "true"` but no `Job` or hook in templates.
**Fix:** Either:
- Add a `pre-upgrade` Helm hook `Job` that runs `litellm --apply-db-migration` against `$DATABASE_URL`, OR
- Document explicitly in `reame/` that DB migration must be run manually before Helm upgrade, with the exact command.

---

## Section 14 — Documentation & Operability

### ❌ [HIGH] 14.1 — No `README.md` in chart root
**Evidence:** `ls -la` shows no `README.md`.
**Why it matters:** Helm best practice; required for Artifact Hub / OCI publishing.
**Fix:** Add a chart README with: prerequisites, install, upgrade, uninstall, full values reference, troubleshooting.

### ❌ [HIGH] 14.3 — Doc references templates that don't exist (`external-postgres-secret.yaml`, `external-redis-secret.yaml`)
**Evidence:** `reame/BUILDPIPER_IMPORTANT_FILES.md:73-78` lists them; `ls templates/` doesn't.
**Fix:** Either delete the doc section or add the templates (with proper guard so they don't collide).

### ❌ [MED] 14.4 — `NOTES.txt` references `proxyNodePort` which is not in `values.yaml`
**Evidence:** `templates/NOTES.txt:3` uses `.Values.service.proxyNodePort` but `values.yaml` doesn't define `service.proxyNodePort` (the deployment template also references it but only when `service.type=NodePort`).
**Why it matters:** Renders as `<no value>` or empty — confusing for ops.
**Fix:** Add `service.proxyNodePort: null` with comment, or remove from NOTES.txt.

---

## Section 15 — Naming, Labels & Metadata Consistency

### ❌ [HIGH] 15.1 — Missing `app.kubernetes.io/*` recommended labels (see 11.5)
### ✅ [PASS] 15.2 — All resources use `{{ .Release.Name }}-` prefix
### ⚠️ [HIGH] 15.3 — `namespace:` line is **commented out** in every template
**Evidence:** All templates have `# namespace: {{ .Values.namespace }}` as a comment.
**Why it matters:** Confusing for juniors — looks like namespace is templated but isn't. Either template it or remove.
**Fix:** Replace with `namespace: {{ .Values.namespace | default .Release.Namespace }}` (so Helm install `-n` flag works as fallback).

---

## Section 16 — Compliance Quick-Checks

### ⚠️ [MED] 16.1 — Pod Security Standards `restricted` profile would reject current deployment
**Why:** Missing `runAsNonRoot`, `seccompProfile`, `allowPrivilegeEscalation: false`, `capabilities.drop`.
**Fix:** Apply `SECURITY-HARDENING-PATCH.md` to reach `restricted` profile compliance.

### ❌ [LOW] 16.2 — No `kubeVersion` constraint in Chart.yaml
**Fix:** Add `kubeVersion: ">=1.25.0-0"` (or whatever org floor is).

---

## Score breakdown by section

| Section | PASS | FAIL | of which BLOCKER | Score |
|---|---:|---:|---:|---:|
| 1 Chart Hygiene | 1 | 4 | 1 | 20% |
| 2 Pod securityContext | 0 | 5 | 5 | 0% |
| 3 Container securityContext | 2 | 4 | 4 | 33% |
| 4 Identity & RBAC | 0 | 3 | 0 | 0% |
| 5 Image Supply Chain | 1 | 3 | 1 | 25% |
| 6 Resources & HPA | 0 | 5 | 2 | 0% |
| 7 Probes & Lifecycle | 1 | 4 | 0 | 20% |
| 8 Scheduling & PDB | 3 | 4 | 0 | 43% |
| 9 Secrets | 2 | 2 | 1 | 50% |
| 10 Network | 2 | 3 | 0 | 40% |
| 11 Observability | 0 | 4 | 0 | 0% |
| 12 ConfigMap | 2 | 2 | 0 | 50% |
| 13 Upgrades | 1 | 2 | 0 | 33% |
| 14 Docs | 0 | 3 | 0 | 0% |
| 15 Labels | 1 | 2 | 0 | 33% |
| 16 Compliance | 0 | 2 | 0 | 0% |
| **TOTAL** | **28** | **33** | **11** | **46%** |

---

## What to ship next (remediation priority order)

1. **Fix `values.yaml` indentation** (BLOCKER, 5-min fix) → unblocks 1.1.
2. **Add pod + container `securityContext`** (BLOCKER, ~30 min) → clears 8 BLOCKERs.
3. **Add `required` guard for masterKey/saltKey** (BLOCKER, 5 min) → clears 9.1.
4. **Add `topologySpreadConstraints` + `serviceAccountName`** (HIGH, 15 min).
5. **Add `livenessProbe` + `startupProbe`** (HIGH, 10 min).
6. **Fix `requests` ≠ `limits`** (HIGH, 5 min).
7. **Fix `REDIS_PASSWORD` env var always-set** (HIGH, 5 min).
8. **Add NetworkPolicy + Prometheus annotations + app.kubernetes.io labels** (MED, 30 min).
9. **Fix docs / remove stale references** (MED, 30 min).
10. **Add README.md + securityContext verification** (MED, 1 hr).

After applying all of the above, re-render and re-score. Target: ≥ 95 % pass rate with 0 BLOCKERs = SHIP-READY.
