# OSS vs Enterprise — LiteLLM and Kong AI Gateway

> Honest, side-by-side breakdown of what's free and what costs money
> on each gateway, so you can see they're playing the same game.
> Plus: a clear recommendation for what to set up given our context.

---

## 1. The Core Truth

**Both LiteLLM and Kong follow the same open-core business model.**
The free OSS edition gives you a working gateway. The Enterprise edition gates the features that large organizations actually pay for.

The question is not "which one is fully free." Neither is. The question is "which one's free tier covers what we need, and which one's Enterprise tier overlaps with what we'd ever buy."

---

## 2. Side-by-Side OSS vs Enterprise Matrix

| Capability | **LiteLLM OSS** | **LiteLLM Enterprise** | **Kong OSS / Konnect Free** | **Kong Enterprise** |
|---|:---:|:---:|:---:|:---:|
| **Core gateway / proxy** | ✅ | ✅ | ✅ | ✅ |
| OpenAI-compatible API surface | ✅ | ✅ | ✅ (via `ai-proxy` plugin) | ✅ |
| 100+ provider adapters | ✅ | ✅ | ⚠️ Limited free; full set in Enterprise | ✅ |
| **Virtual API keys** | ✅ | ✅ | ✅ (consumers + key-auth) | ✅ |
| RBAC | basic teams | 🔒 object-level / orgs | basic | 🔒 fine-grained workspaces |
| **Request rate limits (RPM)** | ✅ | ✅ | ✅ basic | 🔒 advanced rate limiting |
| **Token-aware rate limits (TPM)** | ✅ | ✅ | ❌ | 🔒 `ai-rate-limiting-advanced` |
| **Dollar / cost budgets** | ✅ | ✅ | ❌ | 🔒 `ai-cost-tracking` |
| **Auto spend tracking per key** | ✅ | ✅ | ❌ | 🔒 |
| Programmatic key issuance API | ✅ | ✅ | ✅ | ✅ |
| **Multi-model routing & failover** | ✅ | ✅ | ⚠️ basic | 🔒 `ai-proxy-advanced` (load balance + fallback) |
| Streaming (SSE) | ✅ | ✅ | ✅ | ✅ |
| Exact-match cache | ✅ | ✅ | ✅ basic `proxy-cache` | ✅ |
| **Semantic cache** | ✅ via config | ✅ | ❌ | 🔒 `ai-semantic-cache` |
| **PII redaction** | ✅ via Presidio (custom) | 🔒 named `hide_secrets` shortcut | ❌ | 🔒 `ai-sanitizer` / `ai-pii-sanitizer` |
| **Prompt-injection / jailbreak guard** | ✅ via custom guardrail | 🔒 named `llmguard_moderations` etc. | ✅ basic regex `ai-prompt-guard` | 🔒 `ai-semantic-prompt-guard` |
| Per-key / per-team guardrail toggles | ❌ | 🔒 | ❌ | 🔒 |
| **SSO for admin UI** | ✅ up to 5 users | 🔒 unlimited (Okta, Azure AD, etc.) | ❌ | 🔒 |
| SCIM (auto user provisioning) | ❌ | 🔒 | ❌ | 🔒 |
| **Organizations / multi-tenant orgs** | ❌ | 🔒 Org → Team → Project → Key | ❌ | 🔒 workspaces |
| **Audit logs with retention** | ❌ | 🔒 | ❌ | 🔒 |
| Per-team log routing | ❌ | 🔒 | ❌ | 🔒 |
| **Secret manager integration** (Vault, KMS) | ❌ | 🔒 AWS/Azure/GCP/Vault/CyberArk | ❌ | 🔒 |
| Automated key rotation | ❌ | 🔒 | ❌ | 🔒 |
| Multi-region control plane | ❌ | 🔒 | ❌ | 🔒 |
| **Inference-aware routing** (GPU queue depth) | ❌ | ❌ | ❌ | partial via load-balancing algorithms |
| MCP / agent protocol | basic | basic | basic | ✅ first-class |
| **Tracing (Langfuse, OTel)** | ✅ one-line callback | ✅ | ⚠️ via plugin | ✅ |
| **Prometheus metrics endpoint** | ✅ | ✅ | ✅ basic | ✅ full |
| Cost dashboards in UI | ✅ basic in Logs/Usage | 🔒 enriched | ❌ | 🔒 in Konnect |
| **Developer portal** | ✅ basic admin UI | ✅ + AI Hub | ❌ | 🔒 (paid tier) |
| Custom branding (Swagger/email) | ❌ | 🔒 | ❌ | 🔒 |
| Max request/response size enforcement | ❌ | 🔒 | ✅ via nginx config | 🔒 cleaner UX |
| **WAF** | ❌ | ❌ | ✅ via Coraza/ModSecurity sidecar | 🔒 native plugin |
| Vendor-backed support SLA | ❌ | 🔒 | ❌ | 🔒 |
| **Software cost** | $0 | $$$ contact sales | $0 | $$$ contact sales |

Legend: ✅ free in this tier · 🔒 paid · ❌ not available · ⚠️ partial / requires extra wiring

---

## 3. The Honest Take — What's Actually Different

### Where LiteLLM OSS gives you MORE than Kong OSS for free

These are the LLM-specific capabilities LiteLLM ships free that Kong puts behind Enterprise:

- **Token-aware rate limits (TPM)** — LiteLLM free, Kong Enterprise
- **Dollar / cost budgets per key/team** — LiteLLM free, Kong Enterprise
- **Auto spend tracking** — LiteLLM free, Kong Enterprise
- **Semantic cache** — LiteLLM free, Kong Enterprise
- **Multi-model routing with load balancing + failover** — LiteLLM free, Kong's advanced version (`ai-proxy-advanced`) is Enterprise
- **PII redaction** — LiteLLM free (via Presidio), Kong Enterprise (`ai-sanitizer`)
- **One-line Langfuse tracing** — LiteLLM free, Kong needs more wiring

This is the **single biggest reason** LiteLLM is the right choice for a small/medium AI gateway: every LLM-specific feature you'd actually pay Kong for is free in LiteLLM.

### Where Kong OSS gives you MORE than LiteLLM OSS for free

- **WAF via Coraza/ModSecurity sidecar** — easier in Kong's nginx-based world
- **Generic API gateway features** (header transformations, request routing complexity, oauth2 flows, hundreds of community plugins) — Kong has thousands of plugins, LiteLLM is LLM-only

### Where both free tiers fall short equally

- No SSO at scale (LiteLLM is free up to 5 admin users; Kong has none in OSS)
- No SCIM
- No audit log with retention
- No secret-manager integration
- No multi-region control plane
- No vendor-backed SLA

So if you actually need **enterprise-grade governance**, both products will charge you. The license fee is the price of admission for that bucket of features regardless of which one you pick.

---

## 4. Per-Capability Cost Comparison for OUR Use Case

Mapping our v1 needs to "free or paid":

| What we need | LiteLLM | Kong |
|---|:---:|:---:|
| Issue virtual API keys to clients (BaaS) | ✅ Free | ✅ Free |
| Per-client RPM limits | ✅ Free | ✅ Free (basic) |
| Per-client TPM limits | ✅ Free | ❌ Paid |
| Per-client dollar budgets | ✅ Free | ❌ Paid |
| Per-client model allowlist | ✅ Free | ✅ Free |
| Auto spend tracking per client | ✅ Free | ❌ Paid |
| Multi-provider routing (Gemini, OpenAI, etc.) | ✅ Free | ⚠️ Basic free, advanced paid |
| Failover between providers | ✅ Free | ❌ Paid |
| Exact-match cache | ✅ Free | ✅ Free |
| Semantic cache | ✅ Free | ❌ Paid |
| PII redaction (Presidio) | ✅ Free | ❌ Paid |
| Prompt-injection scanning | ⚠️ Free as custom guardrail | ⚠️ Basic free, advanced paid |
| Tracing dashboard (Langfuse) | ✅ Free | ⚠️ Free with wiring |
| Token counting + cost calc per request | ✅ Free | ❌ Paid |
| Admin UI with virtual key management | ✅ Free | ⚠️ Konnect free tier limited |

**Score:** LiteLLM hits 13/15 entirely free. Kong free hits ~5/15 fully and 4/15 partially — the rest requires Enterprise.

For our v1 list specifically, **LiteLLM OSS = $0 covers everything important. Kong OSS = $0 covers maybe a third, the rest is paid.**

---

## 5. When the Honest Calculus Flips

Kong becomes the right pick when:

- You **already pay for Kong Enterprise** for non-AI traffic (then AI features are an incremental cost, not new)
- You're a **service-mesh shop** and want one data plane (Envoy/nginx) for everything
- You need **inference-aware routing** at GPU-fleet scale (Kong's advanced load balancing has a story here)
- Your org has a **Lua plugin ecosystem investment**
- You need **vendor-backed SLA** for AI traffic specifically

LiteLLM stays the right pick when:

- You're **AI-only or AI-first** and don't need a general API gateway
- You want **all LLM features for free**, paying only when you grow into governance needs
- You want **fastest time to demo** (hours, not weeks)
- You're at small/medium scale (up to a few thousand RPS)
- You want **CNCF-track migration option** (kgateway/Higress) rather than vendor lock-in

---

## 6. The Recommendation

For our context — small team, providing AI as a service to clients, currently 3 EC2 VMs with no Kubernetes — **set up LiteLLM OSS.** This is a clear-cut decision:

### Why

1. **Free covers everything we need.** Token limits, dollar budgets, virtual keys, PII, tracing, multi-provider, semantic cache — all free in LiteLLM. Most of those cost money in Kong.
2. **Faster to ship.** Hours to a working demo, vs days–weeks for Kong + Konnect setup.
3. **No team learning curve on Lua/nginx**. Pure Python, pure Docker.
4. **OpenAI-compatible API as the contract** means clients are portable to any future gateway (Kong, kgateway, Higress) without rewrites.
5. **Migration path is documented**. If we ever outgrow LiteLLM (Sandeep's risk concern, hyperscale, K8s adoption), we move to **kgateway** (CNCF, free, multi-vendor governance) — not paid Kong.

### What to set up — concrete

1. **Today / v1**: LiteLLM OSS + Postgres + Redis (or Valkey) on a single VM, behind Caddy for TLS. Issue virtual keys to clients via the admin UI or `/key/generate` API.
2. **As you grow**: add Presidio + LLM Guard sidecar containers for guardrails. Add Langfuse for the tracing dashboard.
3. **At ~50+ admin users or hard compliance audit**: evaluate LiteLLM Enterprise license for SSO, audit retention, secret-manager hooks. Get the 7-day trial first, run it against real workloads.
4. **At Kubernetes adoption / hyperscale**: migrate to kgateway (CNCF). The supporting services (Presidio, LLM Guard, Langfuse) carry over unchanged.

### When you'd consider Kong instead

Be honest with yourself — only flip to Kong if **two or more** of these are true:

- Your org already has Kong Enterprise and a budget line for it
- You need a unified gateway for AI **and** non-AI traffic
- You need vendor-backed SLA on day one
- You're a 1000+ employee enterprise with serious procurement and support requirements

None of that is true for us right now.

---

## 7. The One-Line Conclusion

> **Both LiteLLM and Kong have free OSS and paid Enterprise tiers — that's the standard open-core model. The difference is what each tier includes: LiteLLM's free tier covers token-aware rate limits, dollar budgets, semantic cache, PII redaction, and Langfuse tracing — all of which require Kong Enterprise. For a small/medium AI-as-a-service deployment like ours, LiteLLM OSS gives us 100% of v1 free, and we'd consider LiteLLM Enterprise only if we cross 50+ admin users or hit a hard SSO/audit compliance requirement.**

---

## 8. Sources

- [LiteLLM Enterprise docs](https://docs.litellm.ai/docs/enterprise) (May 2026)
- [Kong AI Gateway product page](https://konghq.com/products/kong-ai-gateway)
- [Kong Plugin Hub — AI category](https://developer.konghq.com/plugins/?category=ai)
- [Kong AI Gateway 3.8 — semantic caching release](https://konghq.com/blog/product-releases/ai-gateway-3-8)
- [Kong pricing](https://konghq.com/pricing)
- [Zuplo TCO analysis of Kong (notes Enterprise gating)](https://zuplo.com/learning-center/the-true-cost-of-kong-tco-analysis)

*Content above is paraphrased from cited sources for compliance with licensing restrictions. Feature gating shifts release-to-release on both products; treat this as a May 2026 snapshot.*
