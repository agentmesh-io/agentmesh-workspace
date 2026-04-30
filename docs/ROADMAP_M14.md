# 🚂 ROADMAP M14 — Federation, Billing & Studio (v1.2 target)

**Last Updated:** April 30, 2026 (planning — Sprint M13 closed, v1.1.0 released)
**Status:** Planning · Active sprint: TBD on operator confirmation
**Headline:** *"v1.1 made the platform adoptable. v1.2 makes it federated, monetisable, and tunable."*

> **Living document.** Each sprint commit appends to `docs/ACCEPTANCE_M14.x.md` (one file per sub-sprint), mirroring the M13 pattern.

---

## North Star

By the end of M14, an external customer can:

1. **Sign in via their corporate IdP** (Okta / Azure AD / Keycloak) — no shared admin credentials, no provisioning step in our DB.
2. **Be billed** for their token usage and storage with line-item transparency.
3. **Curate a prompt library** in the Studio UI — versioned, RBAC-gated, exportable.
4. **Attach a LoRA adapter** to an LLM provider in seconds — adapter file uploaded, registered, scoped to a tenant or globally.
5. **Install the whole stack on a fresh K8s cluster** with one Helm command — including Postgres / Redis / Kafka — via an umbrella chart.

---

## Composition

M14 is structured as 4 sub-sprints. Each sub-sprint follows the M13.3 cadence
(small commits, versioned acceptance evidence, runtime verification before tick).

| Sub-sprint | Theme | Duration | Tag at end |
|---|---|---|---|
| **M14.1 — Edge OIDC** | OAuth2/OIDC at the Traefik edge + Auto-BADS edge auth | ~2 weeks | `v1.1.1` (security patch) |
| **M14.2 — Billing & Metering** | Token-usage metering, plan tiers, invoice generation, Stripe adapter | ~3 weeks | `v1.2.0-beta.1` |
| **M14.3 — Studio (Prompt Library + LoRA)** | UI surfaces for prompt versioning + LoRA adapter management | ~3 weeks | `v1.2.0-beta.2` |
| **M14.4 — Umbrella Chart + GA** | Bitnami subcharts under `charts/agentmesh-platform/`, dependency lockfile, GA hardening, **`v1.2.0`** tag | ~2 weeks | **`v1.2.0`** |

**Total budget:** ~10 weeks. Aggressive — likely 12 weeks with reviews and external IdP onboarding.

---

## Sprint M14.1 — Edge OIDC

Goal: drop a real corporate IdP in front of AgentMesh without changing the Spring API surface.

- [ ] **Commit 1 — Local IdP (Keycloak) for dev**
  * Add `keycloak` service to `docker-compose.gateway.yml` (port 8085, Postgres-backed, realm `agentmesh-dev` pre-seeded via JSON import).
  * Make target `make idp-up` brings just the IdP; `make demo` chains it.
  * Acceptance: `curl http://idp.agentmesh.localhost/realms/agentmesh-dev/.well-known/openid-configuration` returns 200.

- [ ] **Commit 2 — Traefik forwardAuth → OIDC**
  * Add `oidc-auth@file` middleware (using e.g. `thomseddon/traefik-forward-auth` or `traefik-forward-oidc`).
  * Stack with existing `jwt-auth@docker` (M13.3 c1) so first-party JWTs keep working — OIDC is the *additional* path, not a replacement.
  * Versioned test scenario: Happy (login via Keycloak → cookie → access protected endpoint), Edge (token expires mid-session → silent refresh), Fail (revoked user → 401).

- [ ] **Commit 3 — Auto-BADS edge auth**
  * Attach `jwt-auth@docker` (or `oidc-auth@file`) to the existing `auto-bads-path` Traefik router.
  * Resolve the M13.3-deferred note: "Auto-BADS does not consume our JWT — deferred to M14".
  * Either (a) propagate the upstream JWT as `X-User-*` headers, or (b) issue Auto-BADS a service-account JWT.

- [ ] **Commit 4 — Tenant resolution from OIDC claims**
  * `JwtToTenantContextFilter` extended to read `tenant_id` from custom OIDC claims (e.g., `agentmesh:tenant`).
  * Maps Keycloak group → AgentMesh role (admin / developer / viewer).
  * Regression coverage for existing first-party JWT path.

- [ ] **Commit 5 — Acceptance + `v1.1.1` tag**
  * `docs/ACCEPTANCE_M14.1.md` with verification matrix.
  * `v1.1.1` security-patch tag — no breaking API change.

**Acceptance:** `make demo` brings Keycloak up; UI login redirects to Keycloak; tampered cookie → 401; first-party JWT path unchanged; UAT 21/21.

---

## Sprint M14.2 — Billing & Metering

Goal: every token, every API call, every megabyte of artifact storage is attributable, aggregatable, and billable.

- [ ] **Commit 1 — Metering domain**
  * New module `com.therighthandapp.agentmesh.billing` (Spring Modulith).
  * Entities: `UsageEvent` (tenantId, kind=`llm_token` | `api_call` | `storage_byte_hour`, magnitude, ts), `BillingPeriod`, `Invoice`, `Plan`.
  * Flyway V11 migration for the four tables, partitioned monthly by `ts`.

- [ ] **Commit 2 — Token-usage emission**
  * Hook into existing LLM client(s) (`OpenAICompatibleClient`, etc.).
  * Emit `UsageEvent(kind=llm_token, magnitude=tokens_in+tokens_out)` per call.
  * Async via Spring `@EventListener` → batched insert (no hot-path latency).

- [ ] **Commit 3 — API-call + storage emitters**
  * Servlet filter for `api_call` (with rate-limit-aware sampling).
  * Periodic `@Scheduled` job for storage measurement against `mast_violations`, `blackboard_entries`, etc.

- [ ] **Commit 4 — Plan tiers + quotas**
  * `Plan` table (`STARTER`, `STANDARD`, `ENTERPRISE`) with hard ceilings on each `kind`.
  * Quota check in the request path; exceeded → HTTP 402 Payment Required (RFC 7231 §6.5.2 — first real use).
  * Existing `agentmesh.multitenancy.default-tier` aligns with `STANDARD`.

- [ ] **Commit 5 — Invoice generation**
  * Daily `@Scheduled` job aggregates `UsageEvent` → `Invoice` for closed periods.
  * `GET /api/billing/invoices` (admin-only via `@rbac.admin()`).
  * PDF export via OpenHTMLToPDF (server-side, no JS).

- [ ] **Commit 6 — Stripe adapter (optional, behind feature flag)**
  * `agentmesh.billing.payment-provider=stripe` flag flips invoice push from "draft" to Stripe API.
  * `STRIPE_API_KEY` via Secret.
  * Versioned test scenario covers webhook idempotency.

- [ ] **Commit 7 — Acceptance + `v1.2.0-beta.1` tag**

**Acceptance:** load-test now emits `UsageEvent`s with **<5% throughput regression**; quota exceeded returns 402; daily invoice for a multi-tenant fixture is generated correctly.

---

## Sprint M14.3 — Studio (Prompt Library + LoRA)

Goal: power-user surfaces for the two artifacts our customers care about most.

- [ ] **Commit 1 — Prompt-library backend**
  * Module `prompts` with entities `PromptTemplate`, `PromptVersion` (immutable, content-hashed).
  * Endpoints: list / get / create / new-version / pin (set "active" version) / fork.
  * RBAC: developer can author, admin can pin.

- [ ] **Commit 2 — Prompt-library UI**
  * New `/studio/prompts` page in AgentMesh-UI.
  * Monaco editor with diff view between versions.
  * Variable-binding preview ("test render" against a sample blackboard entry).

- [ ] **Commit 3 — LoRA adapter backend**
  * Module `adapters` with entities `LoRAAdapter`, `AdapterBinding` (tenant- or global-scoped).
  * File upload to MinIO/S3 (or local volume); SHA-256 content addressing.
  * Endpoint to "attach" adapter to an LLM provider runtime.

- [ ] **Commit 4 — LoRA UI**
  * `/studio/adapters` upload + list + attach/detach + per-provider state.

- [ ] **Commit 5 — End-to-end demo path**
  * Update `docs/DEMO_SCRIPT_v1.1.md` → `v1.2.md` to add a 90-second Studio beat.

- [ ] **Commit 6 — Acceptance + `v1.2.0-beta.2` tag**

**Acceptance:** prompt versioning round-trips through UI; LoRA upload + attach against a stub LLM runtime succeeds; existing workflows unchanged.

---

## Sprint M14.4 — Umbrella Chart + GA

Goal: one Helm command on a bare K8s cluster brings everything up.

- [ ] **Commit 1 — Umbrella chart skeleton**
  * `charts/agentmesh-platform/Chart.yaml` declaring `dependencies:` for `agentmesh` (this repo), `bitnami/postgresql`, `bitnami/redis`, `bitnami/kafka`, optional `keycloakx/keycloak`.
  * `Chart.lock` committed (pinned versions).

- [ ] **Commit 2 — Stage values for the umbrella**
  * `values-{dev,staging,prod}.yaml` at the umbrella level, threading down to subchart values.

- [ ] **Commit 3 — `make k8s-demo`**
  * One-command bring-up against `k3d` (local) or any reachable kubeconfig.
  * Companion `scripts/k8s-demo-smoke.sh` mirrors the Compose smoke.

- [ ] **Commit 4 — Hardened defaults rollup**
  * NetworkPolicy across subcharts (Postgres only reachable from agentmesh-api, etc.).
  * PSA labels propagated.

- [ ] **Commit 5 — Documentation refresh**
  * `docs/RELEASE_NOTES_v1.2.md` (mirror v1.1's structure).
  * `docs/UPGRADE_v1.1_to_v1.2.md`.
  * Top-level README "Install" path now shows the Helm one-liner.

- [ ] **Commit 6 — `v1.2.0` tag + GitHub release** 🎉

**Acceptance:** `helm install agentmesh-platform charts/agentmesh-platform -f values-dev.yaml` brings up the full stack on a fresh `k3d` cluster; smoke probe **9/9** within 5 minutes.

---

## Risk Register

| ID | Risk | Severity | Mitigation |
|---|---|---|---|
| **R7** | OIDC misconfiguration locks operators out (no break-glass) | High | M14.1 c2 keeps the first-party `jwt-auth@docker` path active in parallel; `AUTH_ENFORCED=false` env-flag rollback still works. |
| **R8** | Token metering adds tail latency to LLM calls | Medium | M14.2 c2 emits async via `@EventListener` + batched insert — measured against M12 baseline (p95 12.96 ms) with `<5%` regression gate. |
| **R9** | Stripe webhook replay → double billing | Medium | M14.2 c6 idempotency-keyed against `Invoice.externalRef`; webhook handler is idempotent by Stripe `event.id`. |
| **R10** | Prompt-library churn breaks running workflows | Medium | M14.3 versions are **immutable**; pinning happens at the workflow level. Workflows reference `(template_id, version_id)` not just `template_id`. |
| **R11** | LoRA adapter loaded at runtime conflicts with provider's base weights | High | M14.3 c3 ships an `attach --dry-run` validator; provider must accept the adapter shape before it's recorded as `active`. |
| **R12** | Umbrella chart subchart drift (Bitnami publishes a major) | Low | `Chart.lock` pinned; `dependabot` config to bump on schedule with PR review. |
| **R13** | Keycloak realm configuration drift between dev/stage/prod | Medium | Realm exported as JSON to `infra/keycloak/realms/`; checked-in; CI lints. |
| **R14** | Quota 402 breaks existing M13.3 demo lane | Low | Default plan `STANDARD` has generous ceilings (10× M12 load-test numbers); demo is well within. |

---

## Dependencies / Decisions to lock before starting

1. **IdP choice for the dev lane.** Keycloak is the assumed default (open-source, runs locally). If supervisor prefers Authelia or Dex, M14.1 c1 changes shape (smaller footprint).
2. **Billing currency.** Single-currency for v1.2 (`USD`) — multi-currency rides to v1.3.
3. **LoRA storage backend.** MinIO (in-cluster) vs cloud S3. Default proposal: MinIO for the demo lane, S3 in prod via a `values.yaml` toggle.
4. **Schedule.** 10-week aggressive vs 12-week realistic — operator call.

---

## Carry-overs from v1.1

| Source | Item | Lands in |
|---|---|---|
| `docs/RELEASE_NOTES_v1.1.md` "Known issues" | OAuth2/OIDC at the Traefik edge | M14.1 c2 |
| `docs/RELEASE_NOTES_v1.1.md` "Known issues" | Auto-BADS edge JWT attachment | M14.1 c3 |
| `docs/RELEASE_NOTES_v1.1.md` "Known issues" | Helm umbrella chart | M14.4 c1 |
| `docs/ACCEPTANCE_M13.3.md` Finding F1 §3 | `~/infra/onboarding.md` §7c update (ventures own Traefik labels) | Cross-repo with M14.1 c1 (touches infra) |

---

*Each sub-sprint will produce its own `docs/ACCEPTANCE_M14.x.md` evidence document, mirroring the M13.3 pattern.*

