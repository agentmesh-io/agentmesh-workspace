# 📋 PLAN_M13.2 — AuthN/Z & Auto-BADS GA

**Sprint:** M13.2 · **Duration:** 2 weeks · **Repos:** `AgentMesh/`, `AgentMesh-UI/agentmesh-ui/`, `Auto-BADS/`
**Source roadmap:** [docs/ROADMAP_M13.md](ROADMAP_M13.md) §13.2
**Protocol references:** §2 (offline-first), §3 (governance), §4 (versioned scenarios), §7 (micro-sync), §8 (port ranges)

## TL;DR

Replace the API-key shim (`ApiKeyAuthFilter` + stub `AuthController`) with a self-issued **RS256 JWT** model: Spring acts as IdP + resource server, Traefik enforces auth via `forwardAuth → /api/auth/verify`, RBAC is wired through existing `AccessControlService` + `TenantContext` via `@PreAuthorize`. UI gets a login page + token refresh + WS query-param auth. Auto-BADS bumps `1.0.0-RC1 → 1.0.0` and tags.

**Recommendation:** **Self-issued JWT in Spring** (not Keycloak/dex). Rationale: Protocol §2 offline-first, MacBook M4 24 GB envelope, no extra container, RSA keys live on Blackhole SSD already used for `.secrets/` patterns.

---

## 1. Edge: Traefik forwardAuth

The `jwt-auth` middleware is **already declared** in `gateway/dynamic/middlewares.yml` lines 18–24 but never attached. Two routers consume it:

- File config: `gateway/routes/agentmesh.yml` → router `agentmesh-api` `middlewares:` list (currently only ratelimit + cors).
- Docker labels: `docker-compose.gateway.yml` line 70 router `agentmesh-api.middlewares` and line 124 router `auto-bads.middlewares`.

**Action:** Append `jwt-auth@file` to both router middleware chains. Add a **public path bypass** by introducing a second router for `PathPrefix(/api/auth) || PathPrefix(/actuator/health) || PathPrefix(/ws)` with higher priority and **no** `jwt-auth` (WS auth happens in handler — see §6).

## 2. Spring: IdP + Resource Server

### New files (under `AgentMesh/src/main/java/com/therighthandapp/agentmesh/security/`)

| File | Responsibility |
|---|---|
| `SecurityConfig.java` | `SecurityFilterChain` bean: resource-server JWT, `permitAll` for `/actuator/health`, `/api/auth/**`, `/ws/**`, `authenticated()` for rest. CORS bridge to existing `WebConfig`. `@EnableMethodSecurity`. |
| `RsaKeyProvider.java` | `@Component` loading `private_key.pem` + `public_key.pem` from `${agentmesh.security.jwt.keys-dir:/Volumes/Blackhole/.../.secrets/jwt}`. Bootstrap-generates 2048-bit pair if absent (mode 0600). |
| `JwtIssuer.java` | `mint(userId, tenantId, projectId, roles[])` → 15-min RS256 JWT with claims `sub`, `tenant_id`, `project_id`, `roles`, `iat`, `exp`, `jti`. Refresh token = 7-day opaque, stored in Redis (`dev-redis:6381`). |
| `JwtToTenantContextFilter.java` | Per-request `OncePerRequestFilter` after Spring's `BearerTokenAuthenticationFilter`: maps validated JWT claims into `TenantContext` ThreadLocal; clears in `finally`. |
| `AuthenticationService.java` | `login(username, password)` against new `users` table (BCrypt); issues access+refresh; `refresh(refreshToken)` rotates. |

### Files to modify

- `AuthController.java`: replace API-key check with three endpoints — `POST /login`, `GET /verify` (Traefik forwardAuth), `POST /refresh`, `POST /logout` (Redis blocklist of `jti`).
- `ApiKeyAuthFilter.java`: **delete** (or guard behind `agentmesh.security.legacy-api-key.enabled=false` default).
- `pom.xml`: add `spring-boot-starter-security`, `spring-boot-starter-oauth2-resource-server`. `nimbus-jose-jwt` is transitive.
- `application.yml`: add `spring.security.oauth2.resourceserver.jwt.public-key-location`; `agentmesh.security.jwt.access-ttl=PT15M`; `agentmesh.security.jwt.refresh-ttl=P7D`.

### New script

- `scripts/gen-jwt-keys.sh`: `openssl genpkey` 2048-bit + `chmod 600`. Idempotent.

## 3. Per-tenant RBAC

| Endpoint | admin | developer | viewer |
|---|---|---|---|
| `POST /api/workflows/start` | ✅ | ✅ | ❌ |
| `GET /api/workflows/**` | ✅ | ✅ | ✅ |
| `POST /api/projects` | ✅ | ✅ | ❌ |
| `* /api/tenants/**` | ✅ | ❌ | ❌ |
| `GET /api/blackboard/**` | ✅ | ✅ | ✅ |
| `* /api/agents/**` | ✅ | ✅ | ❌ |
| `GET /api/mast/**` | ✅ | ✅ | ✅ |
| `* /api/billing/**` | ✅ | ❌ | ❌ |
| `/api/auth/**`, `/actuator/health` | public | public | public |

## 4. Auto-BADS — v1.0.0 GA

**Discrepancy flagged:** `Auto-BADS/test-run.log` line 2123 currently reports `Tests run: 92, Failures: 0, Errors: 0`. The roadmap "1/128 failing" text predates this run. Action:

1. `cd Auto-BADS && ./mvnw clean verify 2>&1 | tee target/release-test.log` — capture **integration** tests (Failsafe).
2. If a flaky test surfaces, fix with seeded RNG / `@RepeatedTest`; add regression assertion.
3. Bump version: `Auto-BADS/pom.xml` `1.0.0-RC1 → 1.0.0`.
4. Update README badge + CHANGELOG.
5. Tag `git tag -a v1.0.0 -m "Auto-BADS GA"`.
6. Add Traefik route `Host(api.agentmesh.localhost) && PathPrefix(/bads) → strip → auto-bads:8083`.

## 5. Test scenario doc

Create `docs/tests/M13.2-authnz.md` matching style of `docs/tests/M13.1-live-ui.md`:

- **Topology:** Browser → Traefik (forwardAuth) → Spring `/api/auth/verify` → resource server → controller (`@PreAuthorize`).
- **Pre-conditions:** keys generated, seed user, `users` table migrated, `dev-redis` up.
- **Happy (H1–H8):** login → 200 + tokens; verify → 200 with `X-Tenant-Id`; protected GET with Bearer → 200; refresh → new pair; WS `?token=` connect → frame; admin endpoint as admin → 200; viewer reads workflow → 200.
- **Edge (E1–E5):** expired token → 401 + `WWW-Authenticate`; clock skew tolerance; refresh flow; cross-tenant request → 403; concurrent refresh atomic.
- **Fail (F1–F5):** no `Authorization` → 401; tampered signature → 401; viewer POST → 403; revoked `jti` → 401; WS without `?token` → close 4401.
- **k6 smoke:** assert `http_req_failed==0` with header, `==1` without.

## 6. UI changes (`AgentMesh-UI/agentmesh-ui/`)

| File | Change |
|---|---|
| `app/login/page.tsx` *(new)* | Form posting to `/api/auth/login`. |
| `app/api/auth/[...]/route.ts` *(new)* | Next.js route handler proxying login/refresh; sets **httpOnly, SameSite=Lax** cookie `am_at` + `am_rt`. |
| `middleware.ts` *(new)* | Redirect unauth `/dashboard/**`, `/workflows/**`, `/srs/**`, `/submit-idea/**`, `/analysis/**`, `/artifacts/**` to `/login`. |
| `lib/api/agentmesh-api.ts` | Inject `Authorization: Bearer …`; on 401 refresh once + retry. |
| `lib/api/live-stream.ts` | `${WS_URL}?token=${accessToken}` (browsers cannot set WS headers). Re-open on `4401`. |
| `lib/api/backend-service.ts` + `websocket-service.ts` | Same Bearer + retry pattern. |

**Spring side** for WS query-param auth: `HandshakeInterceptor` in `WebSocketConfig` reads `?token=`, validates via `JwtIssuer.parse()`, populates `TenantContext` per session.

## 7. Acceptance criteria (verbatim from ROADMAP §13.2)

> k6 smoke profile passes with Authorization Bearer header; 401 without; Auto-BADS tag `v1.0.0` cut.

Captured as `docs/ACCEPTANCE_M13.2.md` at sprint close.

## 8. Risk register

| # | Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|---|
| R1 | WS `?token=` leaks JWT into Traefik access logs / browser history | High | High | Drop query string from access log; 15-min TTL; rotate on WS reconnect |
| R2 | k6 smoke uses static token → expires mid-run | Med | High | k6 `setup()` calls `/api/auth/login`; per-VU refresh helper |
| R3 | RSA private key on Blackhole SSD survives `git` accident | High | Low | `.gitignore` `.secrets/`; pre-commit scan; 0600 mode |
| R4 | `@PreAuthorize` skipped on a controller leaves silent gap | High | Med | ArchUnit test `controllers_must_have_pre_authorize` |
| R5 | "1/128 failing test" claim outdated → may hide real flake in Failsafe | Med | Med | Run `./mvnw verify`; enable Surefire `rerunFailingTestsCount=0` |
| R6 | UAT/k6 in CI break from sudden auth requirement | High | Med | `AUTH_ENFORCED` flag; default `false` in `dev` until end of sprint |

## 9. Micro-sync commit plan (Protocol §7)

### Repo: `AgentMesh/` (8 commits)
1. `feat(security): add spring-security + oauth2-resource-server deps`
2. `feat(security): RsaKeyProvider + gen-jwt-keys.sh + .secrets/jwt layout`
3. `feat(security): JwtIssuer (RS256, 15m access, 7d refresh via Redis)`
4. `feat(auth): rewrite AuthController (login/verify/refresh/logout)`
5. `feat(security): SecurityConfig + JwtToTenantContextFilter; remove ApiKeyAuthFilter`
6. `feat(rbac): @PreAuthorize on Workflow/Project/Tenant/Agent/Billing controllers`
7. `feat(ws): HandshakeInterceptor for ?token= query auth`
8. `test(security): ArchUnit + WebMvc 401/403 matrix`

### Repo: `AgentMesh-UI/agentmesh-ui/` (5 commits)
1. `feat(auth): /login page + Next route handler with httpOnly cookies`
2. `feat(auth): middleware.ts route guards`
3. `feat(api): inject Authorization header + 401-refresh-retry in ApiClient`
4. `feat(ws): pass ?token= on WebSocket open + 4401 reconnect`
5. `docs: BACKEND_INTEGRATION.md auth section`

### Repo: `Auto-BADS/` (3 commits)
1. `test: stabilize <flaky-test-name> with seeded RNG`  *(if surfaced)*
2. `chore(release): bump version 1.0.0-RC1 → 1.0.0`
3. `docs: CHANGELOG v1.0.0` — then `git tag -a v1.0.0`

### Repo: workspace root (3 commits)
1. `feat(gateway): attach jwt-auth forwardAuth to api + bads routers`
2. `feat(gateway): /bads/* path-strip route via api.agentmesh.localhost`
3. `docs: tests/M13.2-authnz.md + ACCEPTANCE_M13.2.md`

---

*Approved 2026-04-26. Execution begins on commit 1 of `AgentMesh/`.*

