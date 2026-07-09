# Master Helm & Kubernetes Audit Checklist

> **Purpose:** A single, deterministic, machine-readable checklist that any AI agent or junior engineer can use to audit a Helm chart + the Kubernetes workloads it produces. Every item is binary (PASS / FAIL / N/A) and cites the exact `kubectl`/`helm` command or template path that proves the answer.
>
> **Scoring:** PASS = 1, FAIL = 0, N/A = excluded from score. Final verdict:
>
> - **SHIP-READY:** ≥ 95 % pass rate AND no FAIL in sections marked **[BLOCKER]**
> - **CONDITIONAL:** 85 – 94 % pass rate AND no **[BLOCKER]** FAILs — needs sign-off
> - **REJECTED:** < 85 % pass rate OR any **[BLOCKER]** FAIL
>
> **Usage:**
>
> 1. `helm template <release> <chart> > rendered.yaml`
> 2. Walk through each section top-to-bottom.
> 3. Cite evidence inline: `templates/foo.yaml:L42`, `rendered.yaml:L120`, or command output.
> 4. Mark each item PASS / FAIL / N/A.
> 5. Sum at the end → emit verdict.

---

## How to use this with an AI agent

Copy/paste this prompt template:

```
You are a senior K8s/Helm auditor. Audit the Helm chart at <PATH>.

Steps:
1. Run `helm template <release> <PATH> > /tmp/rendered.yaml` (use --set flags if values are required).
2. Run `helm lint <PATH>`.
3. Walk every section of .kimchi/docs/MASTER-HELM-K8S-AUDIT-CHECKLIST.md in order.
4. For each item, emit: [PASS|FAIL|N/A] — evidence (file:line or command output).
5. At the end, emit: SHIP-READY | CONDITIONAL | REJECTED, plus a list of every FAIL with severity [BLOCKER|HIGH|MED|LOW] and the exact remediation.

Do not paraphrase the checklist. Do not skip items. Cite evidence or it does not count.
```

---

## Section 1 — Chart Hygiene (render-time correctness)

| # | Check | How to verify | Severity |
|---|---|---|---|
| 1.1 | `helm template` succeeds with default values | `helm template <release> <chart>` exits 0 | [BLOCKER] |
| 1.2 | `helm lint` exits clean | `helm lint <chart>` returns 0 with no `[ERROR]` lines | [BLOCKER] |
| 1.3 | `helm template` succeeds when `existingSecret: ""` for every secret (default-empty path) | render with `--set <each>.existingSecret=""` exits 0 | [BLOCKER] |
| 1.4 | All template files have unique resource names per release | grep templates for hardcoded `name:`; should be `{{ .Release.Name }}-...` | HIGH |
| 1.5 | `Chart.yaml` declares `apiVersion: v2` | `cat Chart.yaml` | HIGH |
| 1.6 | `Chart.yaml` declares `kubeVersion` (or explicitly omits with justification) | `cat Chart.yaml \| grep kubeVersion` | MED |
| 1.7 | `Chart.yaml` version + `appVersion` both present and consistent with values | compare to `values.yaml` image tag | MED |
| 1.8 | No duplicate secret/config templates that render same resource name | grep rendered.yaml for duplicate `kind: Secret` names | HIGH |
| 1.9 | No commented-out blocks in rendered output | `helm template \| grep -E '^# \|^[[:space:]]*#'` shows only YAML comments, no orphaned logic | LOW |
| 1.10 | Every `if .Values.X` block has matching `{{ end }}` | `helm template` would error otherwise; also `grep -c 'if ' templates/` ≈ `grep -c 'end ' templates/` | HIGH |

---

## Section 2 — Pod-Level `securityContext` **[BLOCKER section]**

| # | Check | How to verify | Severity |
|---|---|---|---|
| 2.1 | `spec.template.spec.securityContext` block exists | grep rendered deployment | [BLOCKER] |
| 2.2 | `runAsNonRoot: true` set at pod level | grep `runAsNonRoot` | [BLOCKER] |
| 2.3 | `runAsUser` and `runAsGroup` set to a non-zero UID (not 0) | grep `runAsUser` | [BLOCKER] |
| 2.4 | `fsGroup` set so PVC/volume mounts are writable by app | grep `fsGroup` | HIGH |
| 2.5 | `seccompProfile.type: RuntimeDefault` (or `Localhost` with explicit profile) | grep `seccompProfile` | [BLOCKER] |
| 2.6 | `sysctls` (if any) restricted to `safe` set | grep `sysctls`; verify against K8s docs | HIGH |

---

## Section 3 — Container-Level `securityContext` **[BLOCKER section]**

| # | Check | How to verify | Severity |
|---|---|---|---|
| 3.1 | `securityContext` set on every container | grep `containers:` then each `securityContext:` | [BLOCKER] |
| 3.2 | `allowPrivilegeEscalation: false` | grep `allowPrivilegeEscalation` | [BLOCKER] |
| 3.3 | `readOnlyRootFilesystem: true` AND writable volumes mounted for runtime dirs (`/tmp`, `/var/run`, app-specific) | grep `readOnlyRootFilesystem` and verify `volumeMounts` covers writable needs | [BLOCKER] |
| 3.4 | `capabilities.drop: ["ALL"]` (and only adds back what's truly needed) | grep `drop:` under `capabilities:` | [BLOCKER] |
| 3.5 | No `privileged: true` unless absolutely required and documented | grep `privileged:` | [BLOCKER] |
| 3.6 | No `hostNetwork: true`, `hostPID: true`, `hostIPC: true` unless required | grep `hostNetwork\|hostPID\|hostIPC` | [BLOCKER] |

---

## Section 4 — Identity & RBAC

| # | Check | How to verify | Severity |
|---|---|---|---|
| 4.1 | `serviceAccountName` explicitly set (not relying on `default`) | grep `serviceAccountName` | HIGH |
| 4.2 | If chart creates the SA, `automountServiceAccountToken: false` unless pod calls K8s API | grep rendered SA | HIGH |
| 4.3 | No cluster-scoped RBAC (ClusterRole/ClusterRoleBinding) unless justified | grep `kind: ClusterRole` | HIGH |
| 4.4 | SA permissions follow least privilege — list verbs explicitly, no `*` | inspect rendered RBAC | HIGH |

---

## Section 5 — Image Supply Chain **[BLOCKER section]**

| # | Check | How to verify | Severity |
|---|---|---|---|
| 5.1 | Image pinned by digest (sha256:...) OR exact tag, never by `latest` | `helm template \| grep image:` | [BLOCKER] |
| 5.2 | `imagePullPolicy` matches use case (`IfNotPresent` for digest-pinned, `Always` only for `latest`) | grep `imagePullPolicy` | HIGH |
| 5.3 | `imagePullSecrets` defined if registry is private | grep `imagePullSecrets` | HIGH |
| 5.4 | No secrets baked into image layers (`envFrom: configMapRef` is fine, `value:` for passwords is not) | grep `value:` under `env:`; flag any with `KEY\|SECRET\|PASSWORD\|TOKEN` | [BLOCKER] |
| 5.5 | Chart documents provenance/signature verification (cosign / SLSA) if org requires it | read README/values comments | MED |

---

## Section 6 — Resource Management & HPA

| # | Check | How to verify | Severity |
|---|---|---|---|
| 6.1 | Every container has both `requests` AND `limits` for CPU and memory | grep `resources:` then `requests:` and `limits:` | [BLOCKER] |
| 6.2 | `requests.cpu` and `requests.memory` are set to non-zero values (required for HPA) | grep rendered | [BLOCKER] |
| 6.3 | `requests` ≤ `limits` (and limits ≠ requests if you want QoS Burstable) | compare | HIGH |
| 6.4 | If HPA enabled, at least CPU OR memory metric configured | grep `metrics:` in HPA | HIGH |
| 6.5 | HPA `behavior` block defined with sane `scaleDown.stabilizationWindowSeconds` (≥ 5 min) | grep `behavior:` | MED |
| 6.6 | If app is bursty, multiple metrics or custom metrics used | review HPA spec | MED |

---

## Section 7 — Health Probes & Lifecycle

| # | Check | How to verify | Severity |
|---|---|---|---|
| 7.1 | `readinessProbe` defined for every container | grep `readinessProbe:` per container | HIGH |
| 7.2 | `livenessProbe` defined for every container | grep `livenessProbe:` per container | HIGH |
| 7.3 | `startupProbe` defined for slow-starting apps (> 30 s to ready) | grep `startupProbe:` | MED |
| 7.4 | Probe `initialDelaySeconds` + `failureThreshold` covers worst-case startup (formula: startup ≥ initialDelay × failureThreshold) | math check vs app cold-start | MED |
| 7.5 | `preStop` hook drains in-flight requests (especially for long-timeout apps) | grep `preStop:` | HIGH |
| 7.6 | `terminationGracePeriodSeconds` ≥ preStop sleep + max in-flight request time | math check | HIGH |

---

## Section 8 — Scheduling, Placement & Availability

| # | Check | How to verify | Severity |
|---|---|---|---|
| 8.1 | `replicas` ≥ 2 for any non-dev workload | grep `replicas:` | HIGH |
| 8.2 | `topologySpreadConstraints` defined for multi-replica workloads | grep `topologySpreadConstraints` | HIGH |
| 8.3 | `podAntiAffinity` (preferred or required) prevents all replicas on one node | grep `podAntiAffinity` | HIGH |
| 8.4 | `priorityClassName` set so critical workloads aren't preempted | grep `priorityClassName` | MED |
| 8.5 | `nodeSelector` / `tolerations` / `affinity` defined if workload has placement constraints | grep | MED |
| 8.6 | PDB exists for any deployment with replicas ≥ 1 | grep `kind: PodDisruptionBudget` | HIGH |
| 8.7 | PDB is sane (`minAvailable` ≤ replicas, not `0`, not `100%` when replicas=1) | math check | HIGH |
| 8.8 | If HPA exists, HPA `maxReplicas` ≥ `replicas` in deployment, otherwise HPA can't actually scale up | compare values | HIGH |

---

## Section 9 — Secrets Management **[BLOCKER section]**

| # | Check | How to verify | Severity |
|---|---|---|---|
| 9.1 | No plaintext secret values in `values.yaml` (must be empty + injected via external Secret) | `grep -E '(password\|token\|key):[^[:space:]]+"[^"]+' values.yaml` | [BLOCKER] |
| 9.2 | All secrets referenced via `secretKeyRef` or `envFrom: secretRef`, never `value:` | grep rendered deployment | [BLOCKER] |
| 9.3 | Secrets created via `stringData` (not `data` with pre-base64'd values) | grep `stringData:` | HIGH |
| 9.4 | Chart supports `existingSecret` pattern (so org can manage Secret lifecycle externally) | grep `existingSecret` per secret | HIGH |
| 9.5 | Default-empty path: chart still renders with `existingSecret: ""` (creates Secret from values, but values must be empty) | `helm template` with `--set <each>.existingSecret=""` | HIGH |
| 9.6 | If chart creates Secret, secret has `type: Opaque` (or specific type like `kubernetes.io/tls`) | grep | MED |
| 9.7 | Secret rotation path documented (how to roll credentials without downtime) | read README | MED |

---

## Section 10 — Network & Traffic

| # | Check | How to verify | Severity |
|---|---|---|---|
| 10.1 | Service `type` matches access pattern (`ClusterIP` for internal, `LoadBalancer`/`Ingress`/`Gateway API` for external) | grep `type:` | HIGH |
| 10.2 | Service has explicit `port.name` (for multi-port services) | grep `name:` under `ports:` | MED |
| 10.3 | Service `selector` matches pod `labels` exactly | compare | [BLOCKER] |
| 10.4 | If Ingress, `ingressClassName` specified | grep `ingressClassName` | HIGH |
| 10.5 | If Ingress, TLS configured (`tls:` block or cert-manager annotation) | grep `tls:` | HIGH |
| 10.6 | If Gateway API, `parentRef` + `hostname` set correctly | grep | HIGH |
| 10.7 | NetworkPolicy exists (default-deny + allow-list) — at minimum an egress policy to external dependencies | grep `kind: NetworkPolicy` | MED |
| 10.8 | No `Service.spec.externalTrafficPolicy` of `Cluster` when source IP preservation matters | grep | LOW |

---

## Section 11 — Observability

| # | Check | How to verify | Severity |
|---|---|---|---|
| 11.1 | Pod annotations expose Prometheus scrape (`prometheus.io/scrape`, `prometheus.io/port`) | grep annotations | MED |
| 11.2 | Structured logging env vars set (`LOG_LEVEL`, `LOG_FORMAT=json`) where supported | grep env | MED |
| 11.3 | Health endpoints (`/health/liveliness`, `/health/readiness`) documented and reachable from probes | curl after deploy | HIGH |
| 11.4 | App exposes metrics port separately from data port (when applicable) | grep ports | LOW |
| 11.5 | Pod labels follow recommended k8s label scheme (`app.kubernetes.io/{name,instance,version,managed-by,component}`) | grep labels | MED |

---

## Section 12 — Configuration & ConfigMap Hygiene

| # | Check | How to verify | Severity |
|---|---|---|---|
| 12.1 | ConfigMap mounted read-only (`readOnly: true`) | grep `readOnly:` on volume mounts | HIGH |
| 12.2 | ConfigMap mounted with `subPath` if file is one of many in directory, to avoid stale mounts on rolling update | grep `subPath:` | MED |
| 12.3 | No secrets in ConfigMap data | grep ConfigMap `data:` for keys matching `*KEY\|*SECRET\|*PASSWORD\|*TOKEN*` | [BLOCKER] |
| 12.4 | ConfigMap `data:` values that look like env interpolation (`os.environ/X`) are resolved at app startup, not at Helm render — and the actual env var exists in container env | trace through deployment | HIGH |
| 12.5 | No hard-coded internal IPs in ConfigMap if chart is reusable across environments — should be templated | grep `192.168.\|10\.\|172.16` in values.yaml | MED |

---

## Section 13 — Upgrade & Rollout Safety

| # | Check | How to verify | Severity |
|---|---|---|---|
| 13.1 | `strategy.type: RollingUpdate` (not `Recreate`) for any stateful-ish workload | grep | HIGH |
| 13.2 | `maxUnavailable: 0` + `maxSurge ≥ 1` for zero-downtime rollouts | grep | HIGH |
| 13.3 | `revisionHistoryLimit` ≥ 3 | grep | MED |
| 13.4 | Pod `terminationGracePeriodSeconds` ≥ app drain time | grep | HIGH |
| 13.5 | PDB does not block rollouts (PDB `minAvailable` < replicas, or PDB `maxUnavailable` > 0) | math | HIGH |
| 13.6 | `DISABLE_SCHEMA_UPDATE=true` pattern (for LiteLLM etc.) has documented manual migration step in upgrade guide | read upgrade doc | MED |

---

## Section 14 — Documentation & Operability

| # | Check | How to verify | Severity |
|---|---|---|---|
| 14.1 | `README.md` exists and covers: install, upgrade, uninstall, values reference, dependencies | ls README.md | MED |
| 14.2 | All `Values.*` paths referenced in templates are documented in `values.yaml` comments | grep templates for `Values\.[^[:space:]]*` and compare to comments | MED |
| 14.3 | Template file names match what docs say exists (no orphans, no duplicates documented-but-missing) | `ls templates/` vs docs | HIGH |
| 14.4 | `NOTES.txt` renders useful post-install info (how to verify, where to find secrets) | `helm template` includes NOTES | LOW |
| 15.1 | Chart works with `--dry-run --debug` | `helm install --dry-run <release> <chart>` exits 0 | HIGH |

---

## Section 15 — Naming, Labels & Metadata Consistency

| # | Check | How to verify | Severity |
|---|---|---|---|
| 15.1 | All resources have `app.kubernetes.io/name`, `app.kubernetes.io/instance`, `app.kubernetes.io/version`, `app.kubernetes.io/managed-by` labels | grep labels | MED |
| 15.2 | `metadata.name` of all resources prefixed with `{{ .Release.Name }}` to allow multiple releases | grep | HIGH |
| 15.3 | No hardcoded namespace (`namespace: ai-gateway` in templates without template) — should be either templated or omitted (let Helm flag `-n` control) | grep `namespace:` | HIGH |

---

## Section 16 — Compliance Quick-Checks

| # | Check | How to verify | Severity |
|---|---|---|---|
| 16.1 | No workload violates Pod Security Standards `restricted` profile (run `kube-score` or `polaris` if available) | `polaris audit --format wide` | MED |
| 16.2 | If org mandates it, chart supports `kubeVersion` constraint that excludes unpatched K8s | grep Chart.yaml | LOW |
| 16.3 | License is OSI-approved | grep Chart.yaml `icon:`/license file | LOW |

---

## How to score

```
total_pass = sum(PASS items)
total_fail = sum(FAIL items, excluding [BLOCKER])
total_blocker_fail = sum(FAIL items in [BLOCKER] sections)
total_na = sum(N/A items)
total_applicable = total_pass + total_fail + total_blocker_fail

score = 100 * (total_pass + 0.5 * (pass-among-blockers-not-required)) / total_applicable
```

Verdict:

- **SHIP-READY:** `total_blocker_fail == 0` AND `score >= 95`
- **CONDITIONAL:** `total_blocker_fail == 0` AND `85 <= score < 95`
- **REJECTED:** `total_blocker_fail > 0` OR `score < 85`

---

## Remediation pattern (template for the report you write back)

For every FAIL:

```
### [SEVERITY] Item <section>.<n> — <one-line title>
**Evidence:** <file:line or command output>
**Why it matters:** <one sentence>
**Fix:**
```diff
- <before>
+ <after>
```
**Verify:** <command that should now exit 0 or return expected value>
```
