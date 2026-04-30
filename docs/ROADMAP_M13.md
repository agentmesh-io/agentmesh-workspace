# 🗺️ M13 — **Post-1.0 Adoption Train** (v1.1 target)

**Status:** Planned  
**Starts:** 2026-04-23  
**Target GA:** 2026-06 (≈ 6 weeks, 3 × 2-week sprints)  
**Hardware envelope:** MacBook Pro M4 Pro (24 GB) — per Architect Protocol v7.24 §1  
**Infra envelope:** Shared `dev-postgres:5435`, `dev-redis:6381`, `dev-traefik`, `dev-rabbitmq`, LMStudio :1234

---

## 🎯 Goal

AgentMesh v1.0 proved the engine runs under load. **M13 makes it usable by humans** — live UI, real authentication, and the full Auto-BADS → AgentMesh customer journey demoable end-to-end.

## 🧭 North-Star KPI

> *A supervisor can submit a business idea through the UI and watch the code being written, then clone the resulting GitHub repo — without ever touching a terminal.*

---

## 🚦 Sprints

### Sprint 13.1 — **Live UI** (2 weeks)
Goal: workflow visualisation in real time.

- [x] WebSocket bridge: Spring `/ws` (`AgentMeshWebSocketHandler`) → UI native client (`lib/api/live-stream.ts`)
- [x] Live agent-activity events (Planner/Architect/Developer/Tester/Reviewer state transitions broadcast from `WorkflowService`)
- [x] Blackboard event stream → UI timeline (Spring `@EventListener` `LiveStreamBridge` + 5 unit tests)
- [x] MAST violation toasts (`MASTViolationService.save()` broadcasts `mast.violation`)
- [x] Register UI at `app.agentmesh.localhost` via shared Traefik (gateway routes both legacy `app.localhost` and `app.agentmesh.localhost`)
- [x] Versioned test scenario `docs/tests/M13.1-live-ui.md` (Happy/Edge/Fail) — Protocol §4
- [x] Dashboard ReactFlow node animation + Blackboard timeline + MAST toasts (`app/dashboard/orchestration/page.tsx`)
- [x] k6 WebSocket latency probe authored (`load-tests/ws-latency.js`)
- [x] Runtime acceptance executed 2026-04-26 — first frame **+31 ms** (≪ 500 ms gate); evidence: `docs/ACCEPTANCE_M13.1.md`
- **Acceptance:** ✅ Start a workflow → nodes light up within 500 ms of backend state change. **Sprint 13.1 DONE.**

### Sprint 13.2 — **AuthN/Z & Auto-BADS GA** (2 weeks)
Goal: production-grade authentication + Auto-BADS 1.0.0 (drops the RC suffix).

- [ ] OAuth2/OIDC at the Traefik edge (forwardAuth → `/api/auth/verify`)
- [x] JWT minted by Spring, RSA keys on Blackhole SSD, 15 min TTL — `JwtIssuer` (RS256) + `RsaKeyProvider` + `scripts/gen-jwt-keys.sh`, verified end-to-end via `/api/auth/login` round-trip 2026-04-26
- [x] Per-tenant RBAC (admin / developer / viewer) wired into every controller (`@PreAuthorize` matrix; `RbacEnforcer` for cross-tenant guard)
- [x] Auto-BADS fix remaining 1/128 test, ship v1.0.0 — tag `v1.0.0` cut 2026-04-26 (128 tests, 0 failures, 0 errors); fixes: graceful-degradation contract in `ErrorRecoveryTest` + Docker-gated `RedisCacheIntegrationTest`
- [x] Single `Host(api.agentmesh.localhost) → /bads/*` path stripped to Auto-BADS (`docker-compose.gateway.yml` router `auto-bads-path` + `bads-stripprefix` middleware)
- [x] UI auth wiring (login page, `/api/auth/{login,refresh,logout}` route handlers, `middleware.ts` redirect gate, `Authorization: Bearer` injection + 401 refresh-and-retry, WS `?token=` with reconnect on close 4401) — `agentmesh-io/agentmesh-ui@762235d`, `next build` clean
- **Acceptance:** ✅ k6 auth-smoke green 2026-04-26 (bearer fail-rate `0`, none `1`, tampered `1`, p95 **313 ms** ≪ 500 ms gate); Auto-BADS `v1.0.0` tag cut. Evidence: [`docs/ACCEPTANCE_M13.2.md`](ACCEPTANCE_M13.2.md). Edge `jwt-auth@file` attachment + `AUTH_ENFORCED=true` flip ride to M13.3 to avoid breaking the v1.0 UAT lane mid-sprint (Risk R6).

### Sprint 13.3 — **Packaging & Demo Day** (2 weeks)
Goal: install anywhere in ≤ 10 minutes.

- [x] **Commit 1 — R6 close**: `AUTH_ENFORCED=true` hard-default in Spring (`SecurityConfig` `@Value` fallback flipped + test profile pinned to `false` for Surefire) + Traefik edge router split (`agentmesh-api-public` priority 100 for `/api/auth/**`, `/actuator/health*`, `/ws/**`, `/actuator/prometheus`, `/v3/api-docs`, `/swagger-ui`; `agentmesh-api` priority 10 with `jwt-auth@docker`); `load-test.js` and `uat-full-flow-v1.sh` now mint a token in setup/Step 0. Rollback handle: `AUTH_ENFORCED=false` env. **Runtime-verified 2026-04-28** (k6 auth-smoke bearer p95=20.5ms ▼15× vs M13.2; load-test smoke 1015/1015 checks, errors=0; UAT 19/21 — see F2 below). Evidence: [`docs/ACCEPTANCE_M13.3.md`](ACCEPTANCE_M13.3.md). Risk R6 closed.
- [x] **Commit 2 — F1+F2 cleanup**: deleted dead `gateway/routes/agentmesh.yml` (workspace; companion infra-side already cleaned in c1). F2 root-caused — *not* Spring Security RBAC after all: `MASTViolation.evidence` carried `@Lob` on a PostgreSQL `text` column, which Hibernate binds via `LargeObjectManager` and PG refuses outside a transaction (`"Large Objects may not be used in auto-commit mode"`); H2 silently tolerated it which is why existing ITs never caught it. Fix dropped `@Lob` (no DB migration — column was already `text` since V1) + new `MASTViolationLobMappingTest` reflection guard. **Runtime-verified 2026-04-28**: 6/6 MAST endpoints HTTP 200 (was 3×403/3×200), UAT **21/21** ▲ back to baseline. Upstream: AgentMesh@`e166b4f`. Evidence: [`docs/ACCEPTANCE_M13.3.md`](ACCEPTANCE_M13.3.md) §"Commit 2".
- [x] **Commit 3 — Helm chart `charts/agentmesh/`**: stage-aware Helm chart (apiVersion v2, version 0.1.0, appVersion 1.1.0) with `values.yaml` (defaults, fail-closed when `ingress.host` empty) + `values-{dev,staging,prod}.yaml` overlays per Architect Protocol §9 (`api.agentmesh.localhost` / `api-stage.agentmesh.localhost` / `api.agentmesh.io`). Templates: SA, ConfigMap, Secret (gated by `existingSecret`), Deployment (with `checksum/config`+`checksum/secret` annotations + Spring Actuator probes), Service, Ingress, HPA, PDB, NetworkPolicy, NOTES. **Verified 2026-04-29**: Helm 4.1.4 installed; `helm lint` + `helm template` clean for all three stages (dev=6 resources, staging=9, prod=8 — Secret externalised); 0 unsubstituted-template sentinels. Evidence: [`docs/ACCEPTANCE_M13.3.md`](ACCEPTANCE_M13.3.md) §"Commit 3", [`charts/agentmesh/README.md`](../charts/agentmesh/README.md).
- [x] **Commit 4 — Hardened K8s manifests**: tightened NetworkPolicy (named-namespace selectors via `kubernetes.io/metadata.name`, RFC1918-deny on HTTPS egress, configurable `ingressFromNamespaces`/`egressToNamespaces`/`extraEgress`); added optional Namespace template with PSA labels (`pod-security.kubernetes.io/enforce`/`audit`/`warn` — staging=`baseline`, prod=`restricted`); added Prometheus Operator `ServiceMonitor` (staging 30 s, prod 15 s) scraping `/actuator/prometheus` on the `http` port; added `topologySpreadConstraints` (zone + hostname, `ScheduleAnyway`, `maxSkew=1`) on prod for HA; tuned HPA behavior to M12 load-test numbers (`scaleUp.stabilizationWindowSeconds=15` + `selectPolicy: Max` over `Percent 100%/30s` and `Pods +2/30s` — calibrated against ramp-peak p95=109 ms while baseline p95=12.96 ms gives 38× headroom). **Verified 2026-04-29**: lint clean for all 3 stages; templates render dev=6/staging=10/prod=9 resources with 0 unsubstituted-template sentinels. PSA replaces the deprecated PodSecurityPolicy (gone in K8s 1.25+). Evidence: [`docs/ACCEPTANCE_M13.3.md`](ACCEPTANCE_M13.3.md) §"Commit 4".
- [x] **Commit 5 — `make demo` target**: workspace-root `Makefile` (17 documented targets) wires up the demo lifecycle in a single command — `prereqs` → `infra-up` → `app-up` → `wait-healthy` (5 min cap) → `demo-smoke` (9 probes) → `demo-urls`. Includes `demo-down` (preserves volumes), `demo-clean CONFIRM=yes` (destructive, gated), `demo-status`, `demo-logs`, and Helm helpers (`helm-lint`, `helm-template-{dev,staging,prod}`). New `scripts/demo-smoke.sh` covers public bypass (health, prometheus), login → 721-char RS256 token, R6 enforcement (no-token=401, tampered=401), authenticated reads incl. F2-regression coverage (`/api/mast/violations/{recent,unresolved}`). **Verified 2026-04-30**: `make help` renders 17 targets; `make demo-status` against live stack confirms `agentmesh-api Up 22h healthy`; `scripts/demo-smoke.sh` returns **PASS=9 FAIL=0**. `docker-compose.yml`'s obsolete `version: '3.8'` removed (Compose v2 warning). Evidence: [`docs/ACCEPTANCE_M13.3.md`](ACCEPTANCE_M13.3.md) §"Commit 5".
- [x] **Commit 6 — Demo storyboard + walkthrough**: `docs/DEMO_SCRIPT_v1.1.md` ships a 9 min 30 s 8-scene storyboard (beat-by-beat timing + narrator track + browser cues + expected outputs + operator checklist) reframed for v1.1's adoption-train arc ("clone → demo → ship"). `scripts/demo-walkthrough.sh` + `make demo-walkthrough` reproduce scenes §1–§6 with `PAUSE`-tunable pacing for live recording. Walkthrough proves all v1.1 deliverables in one run: R6 close (no-token=401, authed=200), F2 fix (mast violations 200/200), 9/9 smoke, helm-lint 3/3 stages clean, prod render with NetworkPolicy RFC1918-deny rule. **Verified 2026-04-30**: `PAUSE=0` end-to-end pass against live stack. Recording itself is a supervisor 3-step task (clean → record → run two make targets). Evidence: [`docs/ACCEPTANCE_M13.3.md`](ACCEPTANCE_M13.3.md) §"Commit 6", [`docs/DEMO_SCRIPT_v1.1.md`](DEMO_SCRIPT_v1.1.md).
- [ ] v1.1.0 tag + GitHub release
- **Acceptance:** Helm chart `lint` + `template` clean; demo finishes without manual intervention.

---

## 📦 Deliverables

| Sprint | Artifact | Owner |
|---|---|---|
| 13.1 | `AgentMesh/.../WorkflowSocketHandler.java`, UI `useWorkflowStream` hook | Agent |
| 13.1 | `docs/tests/M13.1-live-ui.md` | Agent |
| 13.2 | `SecurityConfig.java` with ResourceServer, RSA keypair gen script | Agent |
| 13.2 | `Auto-BADS@v1.0.0` tag + release | Agent |
| 13.3 | `charts/agentmesh/Chart.yaml`, `templates/*`, `values-dev.yaml` | Agent |
| 13.3 | `docs/DEMO_v1.1.md` + recorded screencast | Agent |

---

## 🛡️ Governance checklist (per Protocol §3)

- [ ] Copy latest `~/infra/governance/` templates into `docs/governance/`
- [ ] If external customers join v1.1 beta: copy `~/infra/legal/` into `docs/legal/`
- [ ] Sprint-demo script versioned in `docs/SPRINT_DEMO_M13.md` before release

---

## ⚠️ Risk register

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| WebSocket backpressure under load | Medium | Medium | Re-run `k6 load` with `WORKFLOW_LOAD=1` in 13.1 |
| JWT breaks existing UAT suite | High | Medium | Introduce `AUTH_ENFORCED` flag; UAT runs under auth in CI only |
| Helm chart drifts from docker-compose | Medium | Medium | Single source: `kompose` conversion + manual overrides documented |
| Auto-BADS 1/128 test hides real bug | Medium | Low | Root-cause before skipping; add regression test |

---

## 🔭 After M13

**M14 (post-v1.1):** multi-tenant billing, SSO providers (Okta/Azure AD), prompt-library UI, LoRA adapter management.

**M15 (v2.0 exploration):** Temporal durable workflows, Weaviate-backed long-term agent memory, federated agent marketplace.

