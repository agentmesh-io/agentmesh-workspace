# 🧭 Stage Readiness Assessment — end of Sprint M13.2

**Date:** 2026-04-26 · **Author:** Agent (Architect Protocol §9)
**Scope:** Maturity of `dev / stage / prod` local environments across
the AgentMesh workspace, measured against
[`~/infra/docs/multi-stage-agent-protocol.md`](../../../infra/docs/multi-stage-agent-protocol.md).

> **TL;DR.** Dev is at ~80 %; **stage is at 0 %**; prod is at ~30 %
> for Auto-BADS only. The workspace is **not** yet Protocol §9
> compliant. Closing the gap is one of the M13.3 candidates and
> should ride alongside the Helm chart work (which itself benefits
> from a clean dev/stage/prod split).

---

## 1. Protocol §9 — what "ready" means

A venture is considered **stage-ready** when **all** of the following hold:

1. Three compose overrides exist:
   `docker-compose.[venture].base.yml`, `.dev.yml`, `.stage.yml`, `.prod.yml`.
2. Container names follow `[venture]-[service]-[stage]`.
3. Postgres database isolation: `[venture]_dev` / `[venture]_stage` / `[venture]_prod`.
4. Redis DB indexes: dev = 2, stage = 3, prod = 4.
5. Volume paths under `/Volumes/Blackhole/Developer_Storage/OrbStack/data/[venture]/[service]/[stage]/`.
6. Host-bind ports: dev 3000 (Go) / 8081 (Java) / 5173 (Node); stage = +1; prod = +2.
7. Traefik routes:
   `[venture].localhost` (dev), `[venture]-stage.localhost`, `[venture]-prod.localhost`.
8. Make targets: `[venture]-stages-up`, `[venture]-{dev,stage,prod}-{up,down}`.
9. Verification curl per stage documented in the venture README.
10. Shared foundation (`make staging-foundation-up`) is the prerequisite, **not** duplicated locally.

---

## 2. Inventory

| Repo / venture | Compose files present | Stage variant exists? | Naming compliant? | DB-per-stage? | Redis DB index? | Volume layout? | Traefik hosts? | Make targets? |
|---|---|---|---|---|---|---|---|---|
| `agentmesh-workspace` (root) | `docker-compose.yml` (shared infra duplicate), `docker-compose.gateway.yml` | ❌ | ❌ (`agentmesh-api`, `agentmesh-autobads` — no stage suffix) | ❌ (single `agentmesh` DB) | ❌ (default index 0) | ❌ (Docker named volumes only) | dev only (`api.agentmesh.localhost`, `app.agentmesh.localhost`, `bads.localhost`) | ❌ (no Makefile) |
| `AgentMesh/` (Spring API) | `docker-compose.yml` | ❌ | partial (`agentmesh-api`) | ❌ | ❌ | ❌ | ❌ | ❌ |
| `Auto-BADS/` | `docker-compose.yml`, `.dev.yml`, `.prod.yml` | ❌ (no `.stage.yml`, no `.base.yml`) | ❌ (`autobads-dev`, `autobads` — venture prefix missing) | ❌ (in-process H2 for dev) | ❌ | ❌ | ❌ (no `.localhost` route in own compose; gateway adds it) | ❌ |
| `AgentMesh-UI/` | (no compose; Dockerfile only — runs via root gateway compose) | ❌ | ❌ (`agentmesh-ui`) | n/a | n/a | ❌ | dev only | ❌ |

---

## 3. Stage maturity per venture

| Venture | Dev | Stage | Prod | Headline gap |
|---|---|---|---|---|
| **AgentMesh API** (Spring) | 🟢 80 % — runs against shared `dev-postgres:5435` / `dev-redis:6381` via Traefik; all controllers wired | 🔴 0 % — no `.stage.yml`, no `agentmesh_stage` DB, no `api-stage.agentmesh.localhost` route, no Make target | 🟡 20 % — `Dockerfile` is multi-stage (build + runtime) and produces a usable prod image; **no** `.prod.yml` overlay; secrets aren't externalised | No `[venture]-[service]-[stage]` split |
| **Auto-BADS** | 🟢 75 % — `.dev.yml` works against H2; not wired to shared infra | 🔴 0 % — no `.stage.yml`, no `auto_bads_stage` DB, no `bads-stage.localhost` | 🟡 40 % — `.prod.yml` defines real resource limits + Postgres tuning; image tag is now `v1.0.0`; **no** Helm/K8s manifests yet | Stage missing entirely; prod volumes/secrets not externalised |
| **AgentMesh-UI** (Next 15) | 🟢 90 % — `next build` clean, Traefik routes `app.agentmesh.localhost`; auth wiring complete (M13.2) | 🔴 0 % — no stage host, no `next.config` per-stage overrides | 🟡 30 % — `output: 'standalone'` ready for image build; no `.prod.yml` and no env-injection layer | Single-stage only |
| **Workspace gateway** (Traefik labels) | 🟢 95 % — all dev hosts resolvable, jwt-auth middleware declared, branded `/bads/*` route landed in M13.2 | 🔴 0 % — no `*-stage.localhost` routers | 🟡 30 % — `prod`-style labels exist on `auto-bads` but no isolation | Edge needs duplicate routers with stage suffix |

Legend: 🟢 ≥ 70 %  🟡 30–69 %  🔴 < 30 %

---

## 4. Aggregate scorecard

| Stage | Coverage today | Blockers (high-level) |
|---|---|---|
| **dev**   | **~80 %** | Container names lack `[stage]` suffix; no Make targets; root `docker-compose.yml` duplicates shared infra (drift risk vs. `~/infra/docker-compose.dev.yml`) |
| **stage** | **~0 %**  | Nothing exists: no compose overlays, no `*-stage.localhost` routes, no `*_stage` DBs, no Redis db=3 isolation, no Make targets |
| **prod**  | **~25 %** | Auto-BADS has resource-tuned `.prod.yml`; AgentMesh API has none; UI has none; secrets stay in env files; no Helm chart (M13.3 deliverable) |

---

## 5. Effort estimate to reach 100 % Protocol §9

> All times assume one focused agent on the M4 Pro / 24 GB envelope.

| Workstream | Effort | Notes |
|---|---|---|
| Drop the duplicated root `docker-compose.yml` (Postgres/Redis) and adopt `~/infra/docker-compose.dev.yml` as the single foundation | **0.5 d** | Already greenlit by Protocol §9 §"Shared Staging Foundation" |
| Refactor `docker-compose.gateway.yml` → `docker-compose.agentmesh.base.yml` + `.dev.yml` / `.stage.yml` / `.prod.yml` overlays; rename containers to `agentmesh-api-{dev,stage,prod}` etc. | **1.0 d** | Use the infra template `infra/templates/docker-compose.venture.multi-stage.template.yml` |
| Auto-BADS: add `.base.yml` + `.stage.yml`, rename services to `agentmesh-autobads-{dev,stage,prod}`, point at shared Postgres with `auto_bads_{stage,prod}` DBs | **0.5 d** | `.prod.yml` already most of the way |
| AgentMesh-UI: add `agentmesh-ui-{dev,stage,prod}` services in the workspace base compose with Next-runtime overrides per stage | **0.5 d** | Trivial — single image, three host bindings |
| Traefik routers: duplicate `agentmesh-api`, `agentmesh-ui`, `auto-bads-path` for stage and prod with `*-stage.localhost` / `*-prod.localhost` rules; fan out `jwt-auth@file` only on stage/prod (R6 stays off in dev until M13.3 commit 1) | **0.5 d** | Keeps current dev unaffected |
| `Makefile` at workspace root with `agentmesh-stages-up/down`, `agentmesh-{dev,stage,prod}-{up,down}` plus a `verify` target running the curl matrix per Protocol §9 §"Verification" | **0.5 d** | Mirrors infra hub patterns; no Make file exists today |
| Postgres init for `agentmesh_stage`, `agentmesh_prod`, `auto_bads_stage`, `auto_bads_prod` (the Flyway migrations are stage-agnostic so re-run is safe) | **0.5 d** | Add `CREATE DATABASE` rows to `scripts/init-databases.sql` |
| Per-stage env files (`.env.dev`, `.env.stage`, `.env.prod`) for the UI + JWT keys-dir layout per stage | **0.5 d** | Keys dir already on Blackhole SSD; just split paths |
| Sprint demo script `docs/SPRINT_DEMO_M13.md` runs `make agentmesh-stages-up` and shows three concurrent dashboards | **0.5 d** | Rolls into M13.3 demo deliverable |
| **Total**  | **~5 working days** | Single-agent walking-pace — fits inside the M13.3 two-week box together with the Helm chart |

---

## 6. Recommendation for M13.3 scope

The Helm chart and stage-readiness work are mutually reinforcing — both
deliver a clean three-stage representation of the same topology. We
should bundle them as **M13.3 commits 2–10**, with the deferred
`AUTH_ENFORCED` rollout + edge `jwt-auth@file` attachment landing as
**M13.3 commit 1** (smallest, safest, unblocks stage-prod auth) so the
stage rebuild starts on a fully-authenticated baseline.

Suggested ordering (prevents breakage of the running v1.0 dev stack at
every step):

1. **R6 close**: `AUTH_ENFORCED=true` in Spring + attach `jwt-auth@file`
   to protected routers + public-bypass router (kicks off this turn).
2. Drop duplicated root infra compose; adopt `~/infra/docker-compose.dev.yml`.
3. Workspace base compose `docker-compose.agentmesh.base.yml`.
4. Per-stage overlays (`.dev`, `.stage`, `.prod`) + container renames.
5. Postgres `_stage` / `_prod` databases + Redis DB indexes 3/4.
6. Traefik `*-stage.localhost` + `*-prod.localhost` routers (with
   `jwt-auth@file` always-on for stage/prod).
7. `Makefile` with `agentmesh-stages-up/down/verify` targets.
8. Helm chart `charts/agentmesh/` (M13.3 primary deliverable) reusing
   the same env layering.
9. Hardened K8s manifests (NetworkPolicy, PodSecurityPolicy, HPA).
10. `docs/SPRINT_DEMO_M13.md` walking through the three local stages.

---

## 7. Risk addendum

| Risk (carried over from M13.2) | Status | Notes |
|---|---|---|
| **R6** AUTH_ENFORCED breaking UAT/k6 lanes | Closing in M13.3 commit 1 | Flag-driven; UAT/k6 get a setup() that mints a token |
| Helm drift vs. compose | New | Mitigation: single source of env layering reused by both stacks |
| Stage Postgres collisions on shared `dev-postgres` | Low | `agentmesh_stage` / `agentmesh_prod` are distinct logical DBs |
| OrbStack VM memory pressure with 3 stages of 3 services each | Medium | `make agentmesh-stage-up` (single stage) is the daily driver; full `stages-up` reserved for demos |

---

## 8. Verdict

**The workspace ships a v1.0 product but fails Protocol §9 staging
expectations.** Closing the gap costs ~5 working days. Bundling it
with the M13.3 Helm/Demo scope is the most efficient path; doing it
in isolation later would mean re-doing the chart values layering.

**Recommended decision:** absorb the stage-readiness work into M13.3
without expanding the sprint duration; defer pure feature work
(prompt-library UI, billing) to M14.

