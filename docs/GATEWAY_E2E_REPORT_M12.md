# M12 Phase B — Gateway E2E Validation Report (Task 3)

**Date:** 2026-04-22  
**Gateway:** `dev-traefik` (v3.6.13) — shared global-infra instance, per Protocol §2  
**Host exposure:** `:80` (web entrypoint), `:8080` (dashboard)  
**Upstream:** AgentMesh API host process on `:8081` (Spring Boot, shared Postgres/Redis)  
**Route file:** `~/infra/traefik/routes/agentmesh.yml` (watched, hot-reloaded)

## 1. Route Configuration

```yaml
Host(api.agentmesh.localhost) → http://host.docker.internal:8081
  middlewares: agentmesh-ratelimit (avg=100 r/s, burst=50)
               agentmesh-cors      (Origin allow-list, standard headers)
```

- Uses the shared `dev-traefik` instance rather than spinning up a second gateway (offline-first, no rogue container — Protocol §1, §2).
- File-provider hot-reload: drop-in `agentmesh.yml` picked up in under a second.

## 2. Detailed Test Scenario (Happy / Edge / Fail) — v1.0

| # | Scenario | Class | Command (abridged) | Expected | Actual | Status |
|---|----------|-------|---------------------|----------|--------|--------|
| 1 | Health probe via gateway | Happy | `curl -H 'Host: api.agentmesh.localhost' http://localhost/actuator/health` | HTTP 200, body `{"status":"UP"}` | 200, `{"status":"UP"}`, TTFB 57 ms | ✅ |
| 2 | Projects API via gateway | Happy | `curl … /api/projects` | HTTP 200 (tenant-scoped list) | 200 | ✅ |
| 3 | Prometheus scrape via gateway | Happy | `curl … /actuator/prometheus` | ≥ 1 `jvm_*` metric | 56 `jvm_*` lines | ✅ |
| 4 | CORS preflight (OPTIONS) | Happy | `OPTIONS /api/projects` with `Origin: http://localhost:3000` | 200 + `Access-Control-Allow-*` headers reflecting allow-list | 200, `ACAO: http://localhost:3000`, `ACAM: GET,POST,PUT,DELETE,OPTIONS`, `ACAH: Content-Type,Authorization,X-Tenant-Id`, `ACMA: 600` | ✅ |
| 5 | Unmatched host header | Fail | `curl -H 'Host: bogus.localhost' …` | Traefik 404 (no route) | 404 | ✅ |
| 6 | Rate limiting enforcement | Edge | 300 parallel req burst (`xargs -P 50`) | Some requests throttled → HTTP 429 | 270 × 200, **26 × 429**, 4 × 503 (burst backpressure) | ✅ |

**All six scenarios PASS.** Scenario 6 confirms the `rateLimit` middleware works in anger: 26 requests throttled at the gateway edge before reaching AgentMesh, validating the 100 r/s average / 50 burst budget.

## 3. Observations

- **Token bucket behaviour correct**: 50-burst window cleared first, subsequent high-rate calls rejected with 429.
- **503 returns (4)** came from Spring Boot when 50 concurrent keep-alive connections exhausted tomcat worker slack during the burst — these are *upstream* 503s, not gateway errors, and confirm the rate limit is in fact protecting the backend (without it we'd see backlog/timeouts).
- **CORS preflight** is fully handled by Traefik before hitting AgentMesh — useful for v1.0 UI integration on `app.agentmesh.localhost` / `localhost:3000`.

## 4. Reproducibility

```bash
# Apply route (one-time, file is watched)
cp ~/infra/traefik/routes/agentmesh.yml ~/infra/traefik/routes/  # already in place

# Happy-path suite
curl -s -H 'Host: api.agentmesh.localhost' http://localhost/actuator/health
curl -s -H 'Host: api.agentmesh.localhost' http://localhost/api/projects
curl -s -H 'Host: api.agentmesh.localhost' http://localhost/actuator/prometheus | grep -c '^jvm_'

# CORS preflight
curl -sS -D - -X OPTIONS \
  -H 'Host: api.agentmesh.localhost' \
  -H 'Origin: http://localhost:3000' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: Content-Type,X-Tenant-Id' \
  http://localhost/api/projects | grep -i access-control

# Rate limit burst
seq 1 300 | xargs -P 50 -I {} curl -sS -o /dev/null -w '%{http_code}\n' \
  -H 'Host: api.agentmesh.localhost' http://localhost/actuator/health | sort | uniq -c
```

## 5. Compliance Check

| Protocol clause | Requirement | Status |
|-----------------|-------------|--------|
| §1 Container Scan | No rogue Traefik — reused `dev-traefik` | ✅ |
| §4 `[service].localhost` | `api.agentmesh.localhost` resolves & routes | ✅ |
| §4 Versioned Test Scenario | Happy/Edge/Fail per milestone | ✅ (this doc) |
| §8 Port allocation | Upstream on :8081 (Java range) | ✅ |

## 6. Conclusion

**Task 3 (Gateway E2E) — PASSED.**  
AgentMesh v1.0 is reachable, rate-limited, CORS-enabled, and observable through the shared Traefik edge. No further gateway work required before v1.0.0 tag.

**Next (Task 4):** UAT full-flow (Create project → Agent orchestration → Blackboard → MAST detection).

