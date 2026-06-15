# Pod Security Hardening — Outline Helm Chart

> **Date:** 2026-06-12
>
> **Chart:** `/home/vishaltyagi/Desktop/helm-charts/charts/outline`
>
> **Purpose:** Document all pod-level and container-level security controls applied to the Outline deployment, plus the Redis collaboration mechanism required for multi-replica setups.

---

## Table of Contents

1. [Pod-Level `securityContext`](#1-pod-level-securitycontext)
2. [Container-Level `securityContext`](#2-container-level-securitycontext)
3. [Topology Spread Constraints](#3-topology-spread-constraints)
4. [Read-Only Root Filesystem + Writable Directories](#4-read-only-root-filesystem--writable-directories)
5. [Redis Collaboration URL (Multi-Pod Sync)](#5-redis-collaboration-url-multi-pod-sync)
6. [Before vs After Architecture](#6-before-vs-after-architecture)
7. [Reference Links](#7-reference-links)

---

## 1. Pod-Level `securityContext`

Applied at `spec.template.spec.securityContext` — affects all containers in the pod.

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  runAsGroup: 1001
  fsGroup: 1001
  seccompProfile:
    type: RuntimeDefault
```

| Field | Value | What It Does | Why |
|-------|-------|--------------|-----|
| `runAsNonRoot` | `true` | Forces the container to run as a non-root user, even if the Dockerfile specifies `USER root` | Prevents container escape attacks from gaining root on the host node |
| `runAsUser` | `1001` | Sets the Unix user ID for all containers | Consistent identity; avoids random UID collisions |
| `runAsGroup` | `1001` | Sets the primary group ID | Ensures files created belong to a predictable group |
| `fsGroup` | `1001` | Sets the group for volume ownership | Ensures PVC/shared volumes are writable by the application |
| `seccompProfile` | `RuntimeDefault` | Blocks ~70+ dangerous syscalls | Reduces kernel attack surface with sane defaults |

> **Docs:** https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

---

## 2. Container-Level `securityContext`

Applied at `spec.template.spec.containers[].securityContext` — affects only the Outline container.

```yaml
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
```

| Field | What It Does | Why |
|-------|--------------|-----|
| `allowPrivilegeEscalation: false` | Sets the `no_new_privs` Linux kernel flag on the process | Blocks privilege escalation via `setuid`/`setgid` binaries and prevents switching to a weaker seccomp profile |
| `readOnlyRootFilesystem: true` | Makes the entire root filesystem (`/`, `/usr`, `/app`, `/etc`) read-only | If an attacker gets in, they **cannot** modify application binaries, install malware, or tamper with code |
| `capabilities: drop: [ALL]` | Removes all Linux capabilities from the container process | Web apps don't need capabilities like `CAP_NET_ADMIN` or `CAP_SYS_ADMIN`. Follows least-privilege |

### Writable Directories Needed

`readOnlyRootFilesystem` blocks ALL writes to `/`. But Outline/Node.js needs writable space for temporary work. We mount an `emptyDir` volume at `/tmp`:

```yaml
volumeMounts:
  - name: tmp
    mountPath: /tmp

volumes:
  - name: tmp
    emptyDir: {}
```

| Directory | Volume Type | Purpose | Persisted? |
|-----------|-------------|---------|------------|
| `/tmp` | `emptyDir` | Temporary file uploads, Node.js buffers, runtime cache, temp processing | ❌ No — fresh on every pod restart |
| `/var/lib/outline/data` | PVC (`outline-outline-pvc`) | File attachments, images, avatars, exports | ✅ Yes — RWX persistent storage |

> **Key insight:** The PVC mount overlays the read-only root. Since it's a **separate volume mount**, it remains fully writable. Outline can save user files normally while the rest of the filesystem is locked down.

> **Docs:** https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
> **Docs:** https://man7.org/linux/man-pages/man7/capabilities.7.html

---

## 3. Topology Spread Constraints

```yaml
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        app: outline
```

| Field | Value | Meaning |
|-------|-------|---------|
| `maxSkew: 1` | Max difference of 1 pod per domain | Pods spread evenly — no node has more than 1 extra pod vs others |
| `topologyKey: kubernetes.io/hostname` | Spread across individual nodes | Prevents all pods landing on a single node |
| `whenUnsatisfiable: ScheduleAnyway` | Don't block scheduling | If perfect spread isn't possible, still schedule for availability |

**Why:** Prevents a single node failure from taking down all Outline pods.

> **Docs:** https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/

---

## 4. Read-Only Root Filesystem + Writable Directories

### Full Container Filesystem Layout

```
┌──────────────────────────────────────────────────────┐
│              Security Layers (Stack)                 │
├──────────────────────────────────────────────────────┤
│  • runAsNonRoot: true  → UID 1001                    │
│  • readOnlyRootFS: true → / is read-only             │
│  • allowPrivilegeEscalation: false → no sudo tricks  │
│  • capabilities: drop ALL → no kernel superpowers    │
│  • seccompProfile: RuntimeDefault → syscall filtering│
└──────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────┐
│          Container Root Filesystem (READ-ONLY)       │
│  /app             ← Outline source code              │
│  /usr/bin/node    ← Node.js binary                   │
│  /etc             ← Config files                     │
│  /                ← Everything else                  │
└──────────────────────────────────────────────────────┘
              │                    │
              ▼                    ▼
      ┌─────────────┐     ┌─────────────────┐
      │  /tmp       │     │ /var/lib/outline│
      │  (emptyDir) │     │ /data           │
      │  WRITABLE   │     │ (PVC - RWX)     │
      │  ephemeral  │     │ WRITABLE        │
      └─────────────┘     │ persistent      │
                          └─────────────────┘
```

### File Write Flow — Example: User Uploads an Image

```
User clicks upload
        │
        ▼
LoadBalancer routes request → Pod A
        │
        ▼
┌─────────────────────────────────────────┐
│  Pod A (outline container)              │
│  1. Receives image blob                 │
│  2. Writes to /tmp/upload-123.jpg       │  ← emptyDir (writable)
│     (temporary staging)                 │
│  3. Validates, resizes, generates hash  │
│  4. Moves final file to:                │
│     /var/lib/outline/data/abc.jpg       │  ← PVC (writable)
└─────────────────────────────────────────┘
        │
        ▼
Pod B receives download request for abc.jpg
        │
        ▼
┌─────────────────────────────────────────┐
│  Pod B reads from same PVC mount        │
│  /var/lib/outline/data/abc.jpg          │
│  Serves file to user                    │
└─────────────────────────────────────────┘
```

---

## 5. Redis Collaboration URL (Multi-Pod Sync)

### Why Is This Needed?

Outline has a **real-time collaborative editor** (like Google Docs). Multiple users can edit the same document simultaneously via WebSocket connections.

With a single pod, all WebSocket connections land on the same process → no issue.

With **2+ replicas**, the LoadBalancer round-robins connections → different users may land on **different pods**.

### The Problem Without `REDIS_COLLABORATION_URL`

```
   User A (Mumbai)              User B (Delhi)
   ┌─────────────┐              ┌─────────────┐
   │ edits doc   │              │ edits doc   │
   │ "headline"  │              │ "title"     │
   └──────┬──────┘              └──────┬──────┘
          │                            │
          ▼                            ▼
   ┌─────────────┐              ┌─────────────┐
   │   Pod 1     │              │   Pod 2     │
   │             │     X        │             │
   │ Holds state:│  No sync!    │ Holds state:│
   │ "headline"  │──────────────│ "title"     │
   │  (memory)   │              │  (memory)   │
   └─────────────┘              └─────────────┘

   Result:                                                       
   • Each pod has different document state in RAM                
   • User A doesn't see User B's changes                         
   • Conflicts, lost edits, corrupted document                   
```

**Root cause:** Each pod keeps its own **in-memory document state**. Pods don't talk to each other.

> **Important:** This has **nothing to do with nodes**. Even if Pod 1 and Pod 2 are on the **same node**, they still have separate memory spaces and will conflict. The issue is **replica count > 1**.

### The Fix With `REDIS_COLLABORATION_URL`

```yaml
- name: REDIS_COLLABORATION_URL
  value: "redis://192.168.8.78:6379"
```

```
   User A (Mumbai)              User B (Delhi)
   ┌─────────────┐              ┌─────────────┐
   │ edits doc   │              │ edits doc   │
   │ "headline"  │              │ "title"     │
   └──────┬──────┘              └──────┬──────┘
          │                            │
          ▼                            ▼
   ┌─────────────┐              ┌─────────────┐
   │   Pod 1     │              │   Pod 2     │
   │             │              │             │
   │ Publishes:  │      ┌───────┤ Publishes:  │
   │ "headline"  │      │       │ "title"     │
   └──────┬──────┘      │       └──────┬──────┘
          │             │              │
          └────────────►│              │
                        ▼              │
               ┌─────────────────┐     │
               │  REDIS          │◄────┘
               │  PUB/SUB        │
               │  Channel:       │
               │  "collab:doc-42"│
               │                 │
               │  Event:         │
               │  "headline"     │
               │  "title"        │
               └────────┬────────┘
                        │
                        ▼
               ┌─────────────────┐
               │ Subscribers:    │
               │ • Pod 1 ✓       │
               │ • Pod 2 ✓       │
               │ • Pod 3 ✓       │
               └─────────────────┘
                        │
        ┌───────────────┴───────────────┐
        ▼                               ▼
  User A's screen                 User B's screen
  "I see 'title'                  "I see 'headline'
   from User B!"                   from User A!"
```

### How It Works

| Step | Action | Channel |
|------|--------|---------|
| 1. User A types on **Pod 1** | Pod 1 captures the edit operation | — |
| 2. Pod 1 **publishes** to Redis | `PUBLISH collab:doc-42 {edit_data}` | Redis pub/sub |
| 3. All pods **receive** the message | Pod 2, Pod 3, etc. get notified via subscription | Redis pub/sub |
| 4. Each pod **broadcasts** to its clients | WebSockets push the update to connected browsers | WebSocket |
| 5. Postgres stores final state | Permanent save after real-time sync | `DATABASE_URL` |

- **Redis** handles **real-time synchronization** between pods
- **PostgreSQL** handles **permanent persistence** of the final document

### When Do You Need It?

| Replicas | `REDIS_COLLABORATION_URL` Needed? |
|----------|-----------------------------------|
| **1** | ❌ No — single pod handles everything |
| **2** | ✅ **Yes** — users can land on different pods |
| **5+** | ✅ **Yes** — absolutely mandatory |

---

## 6. Before vs After Architecture

### BEFORE Security Hardening (Default / Less Secure)

```
┌─────────────────────────────────────────────────────┐
│                   Kubernetes Pod                     │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌───────────────────────────────────────────────┐  │
│  │            Outline Container                   │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────────┐   │  │
│  │  │ root    │  │ ALL     │  │ Writable    │   │  │
│  │  │ user    │  │ caps    │  │ / filesystem│   │  │
│  │  │         │  │         │  │             │   │  │
│  │  │         │  │         │  │ attacker    │   │  │
│  │  │         │  │         │  │ can modify  │   │  │
│  │  │         │  │         │  │ anything    │   │  │
│  │  └─────────┘  └─────────┘  └─────────────┘   │  │
│  └───────────────────────────────────────────────┘  │
│                                                      │
│  No topology spread = pods can clump on one node    │
└─────────────────────────────────────────────────────┘
```

### AFTER Security Hardening (Current Setup)

```
┌──────────────────────────────────────────────────────────────────────┐
│                         Kubernetes Namespace                          │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│   ┌────────────────────────────────────────────────────────────────┐  │
│   │  Pod 1  (on Node A)                                            │  │
│   │  ┌─────────────────────────────────────────────────────────┐   │  │
│   │  │  Container: UID 1001                                     │   │  │
│   │  │  ┌─────────────┐  ┌──────────┐  ┌──────────────────┐    │   │  │
│   │  │  │ readOnly    │  │  drop    │  │ /tmp             │    │   │  │
│   │  │  │ / (root FS) │  │ ALL caps │  │ (emptyDir)       │    │   │  │
│   │  │  │             │  │          │  │ writable         │    │   │  │
│   │  │  │ no_new_     │  │          │  └──────────────────┘    │   │  │
│   │  │  │ privs flag  │  │          │  ┌──────────────────┐    │   │  │
│   │  │  │             │  │          │  │ /var/lib/outline │    │   │  │
│   │  │  └─────────────┘  └──────────┘  │ /data (PVC-RWX)  │    │   │  │
│   │  │                                  │ writable         │    │   │  │
│   │  │                                  └──────────────────┘    │   │  │
│   │  └─────────────────────────────────────────────────────────┘   │  │
│   └────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│   ┌────────────────────────────────────────────────────────────────┐  │
│   │  Pod 2  (on Node B)    [separated by topologySpreadConstraints]│  │
│   │  ┌─────────────────────────────────────────────────────────┐   │  │
│   │  │  Same security setup as Pod 1                            │   │  │
│   │  │  Same PVC mount (RWX for shared file access)             │   │  │
│   │  │  Redis Collaboration URL syncs real-time doc edits       │   │  │
│   │  └─────────────────────────────────────────────────────────┘   │  │
│   └────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│   External Services:                                                  │
│   • PostgreSQL (192.168.8.39) — documents, users, metadata            │
│   • Redis (192.168.8.78) — sessions, cache, collaboration sync        │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 7. Reference Links

| Topic | URL |
|-------|-----|
| Kubernetes Security Context | https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| Linux Capabilities | https://man7.org/linux/man-pages/man7/capabilities.7.html |
| Topology Spread Constraints | https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/ |
| Pod Security Standards | https://kubernetes.io/docs/concepts/security/pod-security-standards/ |
| Outline Horizontal Scaling | https://docs.getoutline.com/s/hosting/doc/horizontal-scaling-hkfU5Stao7 |
| Outline File Storage | https://docs.getoutline.com/s/hosting/doc/file-storage-N4M0T5Ypu7 |

---

## Files Modified

| File | Change |
|------|--------|
| `templates/outline-deployment.yaml` | Added `readOnlyRootFilesystem: true`, `/tmp` emptyDir volume, `REDIS_COLLABORATION_URL` env var |

---

> **Bottom line:** The Outline pod now runs as a non-privileged user with a locked-down, read-only root filesystem. The only writable paths are `/tmp` (ephemeral) and `/var/lib/outline/data` (persistent PVC). Multiple pods stay in sync via Redis pub/sub for real-time collaboration, while PostgreSQL handles permanent document storage.
