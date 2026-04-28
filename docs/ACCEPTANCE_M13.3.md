# ✅ Sprint M13.3 — Acceptance Evidence

> **Living document** — appended commit-by-commit through Sprint M13.3.
> Each commit lands one section with its verification matrix, rollback
> handle, and links to the artifacts it produced.

---

## Commit 1 — R6 close: `AUTH_ENFORCED=true` + edge `jwt-auth@file`

**Date:** 2026-04-28
**Author:** Agent (Architect Protocol §2 active operator, §4 versioned testing)
**Risk closed:** **R6** (`AUTH_ENFORCED` deferral from M13.2 — see `docs/ROADMAP_M13.md`).

### Scope (files touched in this commit)

| File | Change |
|---|---|
| `AgentMesh/src/main/java/.../security/SecurityConfig.java` | `@Value` default flipped `:false` → `:true`; startup log notes "R6 closed" |
| `AgentMesh/src/test/resources/application-test.yml` | Pin `agentmesh.security.auth-enforced: false` so Surefire stays green without `@WithMockUser` per controller test |
| `docker-compose.gateway.yml` | Split `agentmesh-api` Traefik labels into a priority-100 `agentmesh-api-public` router (no auth, matches `/api/auth/**`, `/actuator/health*`, `/actuator/info`, `/ws/**`) and a priority-10 `agentmesh-api` router with `api-ratelimit, api-cors, jwt-auth@file`; added `AUTH_ENFORCED=${AUTH_ENFORCED:-true}` env var |
| `load-tests/load-test.js` | Added `setup()` that mints an access token via `/api/auth/login`; protected calls (`/api/projects`, `/api/projects/initialize`) now thread `Authorization: Bearer …` via `authedHeaders(data)`; `/actuator/health` and `/actuator/prometheus` stay header-less to prove the public bypass |
| `test-scripts/uat-full-flow-v1.sh` | New "Step 0: Authenticate" mints a token via `/api/auth/login`; `req()` helper auto-injects `Authorization: Bearer …` when `AUTH_HDR` is set; raw curls in Step 6 (Blackboard text/plain POST + snapshot) propagate `AUTH_HDR` via `${AUTH_HDR:+-H …}` |
| `docs/ROADMAP_M13.md` | Sprint 13.3 box `Commit 1 — R6 close` ticked |
| `docs/STAGE_READINESS_M13.2.md` | §6 ordering item 1 marked **DONE** |
| `docs/ACCEPTANCE_M13.3.md` | this file (new) |

### Files intentionally **not** in this commit

- `gateway/routes/agentmesh.yml` (dead config — Traefik file provider only watches `gateway/dynamic/`; deletion deferred to commit 2)
- Root `docker-compose.yml` shared-infra cleanup (commit 2)
- Per-stage compose overlays / Makefile (commits 3–7)
- `auto-bads-path` `jwt-auth` attachment (deferred to M14 — Auto-BADS does not consume our JWT)

### Verification matrix (run after `docker compose -f docker-compose.gateway.yml up -d --build agentmesh-api traefik`)

| # | Probe | Expectation | Notes |
|---|---|---|---|
| 1 | `mvn -pl AgentMesh test` | green | `application-test.yml` keeps integration tests permit-all |
| 2 | `curl -i -H 'Host: api.agentmesh.localhost' http://localhost/actuator/health` | **200** + `"status":"UP"` | Public bypass — header-less |
| 3 | `curl -i -H 'Host: api.agentmesh.localhost' -X POST http://localhost/api/auth/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin-change-me"}'` | **200** + `accessToken` | Public bypass |
| 4 | `curl -i -H 'Host: api.agentmesh.localhost' http://localhost/api/workflows` (no token) | **401** + `WWW-Authenticate: Bearer` | Edge `jwt-auth@file` |
| 5 | Same as #4 with `Authorization: Bearer $TOKEN` | **200** | Forward-auth ➔ verify ➔ allow |
| 6 | Same as #4 with tampered token (last 3 chars flipped) | **401** | RS256 signature check |
| 7 | `k6 run -e BASE_URL=http://api.agentmesh.localhost load-tests/auth-smoke.js` | bearer `fail-rate=0`, none `1`, tampered `1`, `p(95) < 500ms` | M13.2 baseline 313 ms |
| 8 | `k6 run --env PROFILE=smoke load-tests/load-test.js` (with new `setup()`) | `p(95) < 1000ms`, `errors < 5%` | Bearer-aware |
| 9 | `bash test-scripts/uat-full-flow-v1.sh` | **20/20 PASS** | Step 0 login + propagation |
| 10 | UI smoke at `http://app.agentmesh.localhost/login` → dashboard renders → WS frame received | manual ✅ | M13.2 wiring already auth-aware |

### Status (live)

> 🟡 **Code-complete, runtime verification pending.** Edits land in this
> commit; the verification matrix above will be executed against the
> running shared-infra + gateway stack and the per-row results recorded
> in this section before the commit ships to `origin/main`.

### Risk addendum (new in this commit)

| ID | Risk | Severity | Mitigation |
|---|---|---|---|
| R6.1 | Two-router priority misorder leaks `/api/auth/login` to `jwt-auth@file` (would 401 the login itself, deadlock) | High | `agentmesh-api-public.priority=100` >> `agentmesh-api.priority=10`; verification row #3 is the sentinel |
| R6.2 | Stale duplicate router in `gateway/routes/agentmesh.yml` | Medium | Confirmed dead — Traefik file provider directory is `/etc/traefik/dynamic` only; cleanup deferred to commit 2 |
| R6.3 | UI static page ping hits a now-protected route | Low | UI's `middleware.ts` (M13.2) already redirects 401 → silent refresh → login |
| R6.4 | Auto-BADS UAT lane breaks if someone attaches `jwt-auth@file` to `auto-bads-path` | Medium | Explicit comment-free in this commit; intentional deferral to M14 |

### Rollback (single env flag)

```sh
# in workspace root .env (or compose override)
echo "AUTH_ENFORCED=false" >> .env
docker compose -f docker-compose.gateway.yml up -d agentmesh-api
# (optional) detach jwt-auth@file from agentmesh-api router by reverting
# the docker-compose.gateway.yml labels block — single git revert.
```

No DB migration, no data path change.

---

*Subsequent commits in M13.3 will append further sections here.*

