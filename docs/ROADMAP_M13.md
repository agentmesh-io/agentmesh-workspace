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
- [x] Blackboard event stream → UI timeline (Spring `@EventListener` `LiveStreamBridge`)
- [x] MAST violation toasts (`MASTViolationService.save()` broadcasts `mast.violation`)
- [x] Register UI at `app.agentmesh.localhost` via shared Traefik (gateway routes both legacy `app.localhost` and `app.agentmesh.localhost`)
- [x] Versioned test scenario `docs/tests/M13.1-live-ui.md` (Happy/Edge/Fail) — Protocol §4
- [ ] Dashboard ReactFlow node animation + Blackboard timeline component (UI page wiring)
- [ ] k6 latency probe to confirm <500 ms p95 under `WORKFLOW_LOAD=1`
- **Acceptance:** Start a workflow from UI → see nodes light up within 500 ms of backend state change.

### Sprint 13.2 — **AuthN/Z & Auto-BADS GA** (2 weeks)
Goal: production-grade authentication + Auto-BADS 1.0.0 (drops the RC suffix).

- [ ] OAuth2/OIDC at the Traefik edge (forwardAuth → `/api/auth/verify`)
- [ ] JWT minted by Spring, RSA keys on Blackhole SSD, 15 min TTL
- [ ] Per-tenant RBAC (admin / developer / viewer) wired into every controller
- [ ] Auto-BADS fix remaining 1/128 test, ship v1.0.0
- [ ] Single `Host(api.agentmesh.localhost) → /bads/*` path stripped to Auto-BADS
- **Acceptance:** `k6` smoke profile passes with Authorization Bearer header; 401 without; Auto-BADS tag `v1.0.0` cut.

### Sprint 13.3 — **Packaging & Demo Day** (2 weeks)
Goal: install anywhere in ≤ 10 minutes.

- [ ] Helm chart `charts/agentmesh/` (values for dev / staging / prod)
- [ ] Hardened K8s manifests: NetworkPolicy, PodSecurityPolicy, HPA tuned for load-test numbers
- [ ] `make demo` target: brings up the full stack in a fresh checkout
- [ ] Screen-recorded demo: idea → SRS → code → GitHub repo, under 10 min
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

