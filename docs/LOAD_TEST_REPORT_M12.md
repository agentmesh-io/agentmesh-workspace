# M12 Phase B — Load Test Report (Task 2)

**Date:** 2026-04-22  
**Tester:** Automated (k6 v1.7.1)  
**Target:** AgentMesh API on `http://localhost:8081` (shared infra: dev-postgres:5435, dev-redis:6381)  
**Profile:** Headless, no Auto-BADS (SKIP_AUTOBADS=1), no async workflow (WORKFLOW_LOAD=0)  
**Hardware:** MacBook Pro M4 Pro (24 GB RAM) — per Protocol v7.24 §1

## 1. Acceptance Criteria (RELEASE_NOTES_v1.0.md)

| Metric | Smoke threshold | Load threshold |
|--------|-----------------|----------------|
| http_req_duration p95 | < 1000 ms | **< 500 ms** |
| custom `errors` rate | < 5 % | **< 1 %** |
| http_req_failed rate | < 5 % | < 5 % |

## 2. Results

### 2.1 Smoke profile (5 VUs, 40 s)

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| http_req_duration p95 | **23.70 ms** | < 1000 ms | ✅ |
| http_req_duration avg | 8.90 ms | — | ✅ |
| http_req_duration max | 64.52 ms | — | ✅ |
| errors (custom rate) | **0.000 %** (0/1025) | < 5 % | ✅ |
| http_req_failed | **0.000 %** (0/615) | < 5 % | ✅ |
| checks | **100 %** (1025/1025) | — | ✅ |
| iterations | 205 @ 5.07 /s | — | — |
| http_reqs | 615 @ 15.22 /s | — | — |

Source: `load-tests/results/smoke-final-20260422-225256.json`

### 2.2 Load profile (ramp to 100 VUs, 60 s)

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| http_req_duration p95 | **12.96 ms** | < 500 ms | ✅ |
| http_req_duration avg | 4.24 ms | — | ✅ |
| http_req_duration max | 109.48 ms | — | ✅ |
| errors (custom rate) | **0.000 %** (0/22335) | < 1 % | ✅ |
| http_req_failed | **0.000 %** (0/13401) | < 5 % | ✅ |
| checks | **100 %** (22335/22335) | — | ✅ |
| iterations | 4467 @ 74.17 /s | — | — |
| http_reqs | 13401 @ 222.52 /s | — | — |

Source: `load-tests/results/load-final-20260422-225256.json`

### 2.3 Headroom vs. acceptance thresholds (load profile)

- p95 latency: **12.96 ms vs 500 ms budget → 38.6× headroom**
- error rate: **0.000 % vs 1 % budget → ∞ headroom (zero failures over 13 401 requests)**

## 3. Endpoints exercised

Each iteration hits four read/health endpoints (HTTP `GET`):

1. `GET /actuator/health` — Spring Boot health (Postgres, Redis, Weaviate up)
2. `GET /api/projects` — project list (DB read)
3. `GET /actuator/prometheus` — Prometheus metrics export
4. *(optional)* `GET /actuator/health` on Auto-BADS — **skipped** for v1.0 (separate service)

Write/workflow endpoint `POST /api/projects/initialize` is **gated behind `WORKFLOW_LOAD=1`** because it triggers GitHub export + event publishing + LLM calls, which are integration-tier, not API-tier, concerns. Workflow-level load testing is scheduled for M13.

## 4. Test Scenario Versioning (Protocol §4)

| Scenario | VUs | Duration | Expected outcome | Actual |
|----------|-----|----------|------------------|--------|
| **Happy path** — healthy AgentMesh | 5 → 100 | 100 s total | 100 % checks pass, p95 < 500 ms | ✅ 100 %, p95 12.96 ms |
| **Edge** — sustained ramp to 100 VUs | ramp 15 s → hold 30 s | 60 s | stable p95, no queue buildup | ✅ max 109 ms only during ramp; avg 4.24 ms |
| **Fail** — downstream absent (Auto-BADS) | 5 | 40 s | gated off cleanly via `SKIP_AUTOBADS=1` | ✅ no false alarms |

## 5. Commands (reproducible)

```bash
# Smoke
SKIP_AUTOBADS=1 k6 run --env PROFILE=smoke load-tests/load-test.js

# Load (acceptance criteria)
SKIP_AUTOBADS=1 k6 run --env PROFILE=load load-tests/load-test.js

# Stress (optional)
SKIP_AUTOBADS=1 k6 run --env PROFILE=stress load-tests/load-test.js

# Full workflow (M13 scope)
WORKFLOW_LOAD=1 k6 run --env PROFILE=load load-tests/load-test.js
```

## 6. Conclusion

**Task 2 (Load Testing) — PASSED.**  
AgentMesh v1.0 meets and vastly exceeds every published acceptance threshold on the target hardware. No tuning required before v1.0.0 tag.

**Next (Task 3):** Gateway E2E validation via Traefik (`api.localhost`, rate limiting, CORS).

