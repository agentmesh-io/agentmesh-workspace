# 🗺️ AgentMesh Platform — ROADMAP

**Last Updated:** April 30, 2026 (M13 closed — v1.1.0 Adoption Train released)
**Status:** Released — **v1.1.0 Adoption Train**.  Active sprint: **M14 (post-v1.1 — SSO + Billing + Prompt Library)**

---

## Platform Overview

| Project | Version | Stage | Health |
|---------|---------|-------|--------|
| **AgentMesh** (Backend) | **v1.1.0** | Released | 🟢 [Adoption Train release](https://github.com/agentmesh-io/agentmesh/releases/tag/v1.1.0) |
| **AgentMesh-UI** (Frontend) | v0.3.0 | ~90 % feature-complete; auth-wired via M13.2 | 🟢 Bundled under v1.1.0 release |
| **Auto-BADS** (Analysis) | v1.0.0 | Released | 🟢 [v1.0.0 tag](https://github.com/agentmesh-io/auto-bads/releases/tag/v1.0.0) |
| **Workspace** | v1.1.0 | Released | 🟢 [Adoption Train release](https://github.com/agentmesh-io/agentmesh-workspace/releases/tag/v1.1.0) |

---

## High Priority: Protocol Alignment

> Per v7.3 standards, the following must be resolved before new features:

- [x] **Git Hygiene**: ✅ Committed all uncommitted work (April 17, 2026)
- [x] **Branch Merges**: ✅ Merged phase5 + appmod → main (April 17, 2026)
- [x] **GitHub Sync**: ✅ Created repos and pushed (April 17, 2026)
- [x] **File Organization**: ✅ Completed (April 17, 2026)

---

## Completed Milestones

### ✅ M1 — Core Architecture (AgentMesh)
- Blackboard pattern, Agent orchestration, DDD structure
- Multi-tenancy (Postgres schemas, tenant isolation)
- Vectorization (Weaviate integration)

### ✅ M2 — MAST Safety (AgentMesh)
- 14 failure mode detection & mitigation
- Circuit breakers, fallback strategies

### ✅ M3 — Hybrid Search & Monitoring (AgentMesh)
- Phase 5: Hybrid search (keyword + vector)
- Prometheus metrics + Grafana dashboards
- E2E testing framework

### ✅ M4 — UI Dashboard (AgentMesh-UI)
- Orchestration dashboard (ReactFlow)
- Agent/Project/LLMOps management
- Monaco code editor, GitHub export
- WebSocket real-time updates

### ✅ M5 — Business Analysis Engine (Auto-BADS)
- SWOT, PESTEL, PMF, Innovation analysis
- Financial analysis (TCO, LSTM+LLM, XAI)
- Solution synthesis (Build/Buy/Hybrid)
- 127/128 tests passing

### ✅ M6 — Java Modernization (AgentMesh)
- OpenRewrite migration to Java 22 / Spring Boot 3.5
- Workflow persistence (JPA + Flyway V7)
- Ollama LLM configuration

---

## Upcoming Milestones

### ✅ M7 — Git & DevOps Foundation (April 2026)
- [x] Execute git versioning strategy ✅
- [x] Set up GitHub repos under `agentmesh-io` org ✅
- [x] Add CI/CD pipelines (GitHub Actions) ✅
- [x] Add proper `.env.example` files ✅

### ✅ M8 — End-to-End Integration (April 2026)
- [x] Auto-BADS → AgentMesh pipeline ✅ (ProjectController + /api/projects/initialize)
- [x] Full UI → Backend → Analysis flow ✅ (projectsApi + flow tracking endpoint)
- [x] Integration test suite ✅ (ProjectControllerTest contract tests)
- [x] Error handling & retry logic ✅ (DLQ in EventConsumer, circuit breaker in Auto-BADS)
- [ ] Runtime E2E validation → deferred to M12 (requires services running)

### ✅ M9 — Real LLM Integration (April 2026)
- [x] Replace MockLLMClient with real providers ✅ (OpenAICompatibleClient)
- [x] Multi-provider support ✅ (LMStudio, Ollama, OpenAI via single client)
- [x] Token usage tracking & cost management ✅ (built into client)
- [ ] Prompt management system → deferred to post-v1.0
- [ ] Runtime validation → deferred to M12 (requires LMStudio running)

### ✅ M10 — API Gateway & Service Mesh (April 2026)
- [x] Traefik API gateway ✅ (docker-compose.gateway.yml)
- [x] Service discovery ✅ (Docker labels-based routing)
- [x] Rate limiting & auth (API key + forwardAuth) ✅
- [x] Inter-service communication hardening ✅ (circuit breaker, retry, security headers)
- [ ] JWT/OAuth2 → deferred to M12 production hardening

### ✅ M11 — Production Hardening (April 2026)
- [x] Security audit (OWASP Top 10) ✅ (CVE scan + OWASP dependency-check in CI)
- [x] CVE remediation ✅ (postgresql, kafka-clients, assertj-core fixed)
- [x] Config alignment with ~/infra/onboarding.md ✅ (ports, credentials, shared infra)
- [x] K8s deployment manifests (started)
- [x] Disaster recovery ✅ (phoenix-backup.sh + lazarus-restore.sh)
- [x] Logging aggregation ✅ (JSON structured logging, ELK/Loki ready)
- [x] **Sprint Demo M7–M11** ✅ (see docs/SPRINT_DEMO_M7_M11.md)
- [ ] PII encryption (AES-256) → M12
- [ ] Load testing & performance tuning → M12

### 🔲 M12 — v1.0 Release (Target: May 2026)
#### Phase A — Offline (Complete ✅)
- [x] PII encryption (AES-256-GCM) ✅ (AesEncryptAttributeConverter + Tenant entity + V8 migration)
- [x] Load test scripts ✅ (k6 with smoke/load/stress profiles)
- [x] Feature freeze & code review ✅ (TODO audit, version bump to 1.0.0-RC1)
- [x] Documentation review & consolidation ✅ (archived 5 stale docs, updated index)
- [x] Release notes ✅ (RELEASE_NOTES_v1.0.md)

#### Phase B — Runtime (Requires shared infra)
- [x] Runtime E2E validation ✅ (shared infra up; see E2E_VALIDATION_REPORT.md — commit d0b7bef)
- [x] Port alignment to Protocol §8 ✅ (AgentMesh on :8081 — commit 7f68488)
- [x] Load testing execution & performance tuning ✅ (k6 smoke+load PASSED; p95=12.96ms @ 100 VUs, 0 errors/13 401 req; see LOAD_TEST_REPORT_M12.md)
- [x] Gateway E2E validation ✅ (routed via shared dev-traefik; Happy/Edge/Fail 6/6 PASS; rate-limit 429 enforced; see GATEWAY_E2E_REPORT_M12.md)
- [x] User acceptance testing ✅ (20/20 PASS via gateway; project init, workflow start, blackboard persistence, 14 MAST failure modes; see UAT_REPORT_M12.md)
- [x] Tag v1.0.0 & production deployment ✅ (AgentMesh/pom.xml 1.0.0-RC1 → 1.0.0, annotated tag v1.0.0, GitHub release published)

### ✅ M13 — Post-1.0 Adoption Train (closed 2026-04-30 — **v1.1.0 released**)

See **[ROADMAP_M13.md](./ROADMAP_M13.md)** for the full plan and **[RELEASE_NOTES_v1.1.md](./RELEASE_NOTES_v1.1.md)** for shipped scope.

- **Sprint 13.1 — Live UI** ✅ (code-complete + runtime-verified): backend live broadcasts on phase transitions, `LiveStreamBridge` for Blackboard, MAST violation toasts, native WS client, orchestration page wired to live stream, Traefik routes, versioned test scenario, k6 WS-latency probe.
- **Sprint 13.2 — AuthN/Z + Auto-BADS GA** ✅: RS256 JWT with `JwtIssuer` + `RsaKeyProvider`, per-tenant RBAC matrix, UI auth wiring (login + middleware + 401 refresh), k6 auth-smoke green (bearer p95 313 ms), Auto-BADS v1.0.0 cut (128/128 tests).
- **Sprint 13.3 — Packaging & Demo Day** ✅ (7-of-7 commits): R6 close (`AUTH_ENFORCED=true` + edge `jwt-auth@docker`), F2 fix (JPA `@Lob` autocommit trap), Helm chart `charts/agentmesh/` (dev/staging/prod), hardened K8s (NetworkPolicy/PSA/HPA-tuned/ServiceMonitor), `make demo` + 9-probe smoke, demo storyboard + walkthrough, **v1.1.0 tag + GitHub release**.
- **Acceptance:** k6 auth-smoke bearer p95 **20.5 ms** (15× faster than M13.2), `load-test smoke` 1015/1015 checks pass with 0 errors, UAT **21/21**, Helm lint clean for all 3 stages, `make demo` cold-start ~3 min / warm ~30 s, smoke probe **9/9 PASS**. Evidence: [`docs/ACCEPTANCE_M13.3.md`](ACCEPTANCE_M13.3.md).

### 🔲 M14 — Federation, Billing & Studio (v1.2 target)

See **[ROADMAP_M14.md](./ROADMAP_M14.md)** for the full plan.

Carry-overs from v1.1: OAuth2/OIDC at the Traefik edge (forwardAuth → external IdP), Auto-BADS edge-JWT attachment.

New scope: SSO providers (Okta / Azure AD / Keycloak), multi-tenant **billing & metering**, **prompt-library UI**, **LoRA adapter management**, Helm umbrella chart with Bitnami subcharts.

---

## Risk Register

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Unmerged branches cause conflicts | ~~High~~ | ~~High~~ | ✅ Resolved — all merged |
| Uncommitted work lost | ~~Critical~~ | ~~Medium~~ | ✅ Resolved — all pushed to GitHub |
| No CI/CD — regressions undetected | ~~High~~ | ~~High~~ | ✅ Resolved — GitHub Actions CI added |
| MockLLM masks integration issues | ~~Medium~~ | ~~High~~ | ✅ Resolved — OpenAICompatibleClient added (M9) |
| Single developer — bus factor 1 | High | - | Document everything, push to GitHub |
| No automated security scanning | ~~Medium~~ | ~~Medium~~ | ✅ Resolved — OWASP + CVE scanning in CI |

---

## References

- [Git Versioning Strategy](./GIT_VERSIONING_STRATEGY.md)
- [Project Analysis Report](./PROJECT_ANALYSIS_REPORT.md)
- [Sprint Demo M7–M11](./SPRINT_DEMO_M7_M11.md)
- [Release Notes v1.0](./RELEASE_NOTES_v1.0.md)
- [Visual Roadmap](./VISUAL_ROADMAP.md)

