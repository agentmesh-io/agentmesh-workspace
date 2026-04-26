# ✅ Sprint M13.2 — Acceptance Evidence

**Sprint:** M13.2 (AuthN/Z & Auto-BADS GA)
**Captured:** 2026-04-26 21:08 +04:00
**Run-by:** Agent (Architect Protocol §4)

## Acceptance criteria (verbatim from `docs/ROADMAP_M13.md` §13.2)

> *k6 smoke profile passes with `Authorization` Bearer header; 401 without; Auto-BADS tag `v1.0.0` cut.*

---

## 1. Auto-BADS `v1.0.0` cut ✅

- Tag: `agentmesh-io/auto-bads@v1.0.0` (commit `1630d68`).
- Surefire: **128 tests / 0 failures / 0 errors** (1 `@Disabled`,
  Redis IT skips cleanly when no Docker daemon — see
  `Auto-BADS/CHANGELOG.md`).
- Workspace ref: `agentmesh-workspace@45a8acf`.

## 2. k6 smoke gate ✅

Command:

```sh
k6 run \
  -e BASE_URL=http://api.agentmesh.localhost \
  -e USERNAME=admin \
  -e PASSWORD=admin-change-me \
  load-tests/auth-smoke.js
```

Result (5 VUs × 30 shared iterations × 3 calls = 90 requests):

| Tag        | `http_req_failed` rate | Threshold     | Verdict |
|------------|------------------------|---------------|---------|
| `bearer`   | **0**                  | `==0`         | ✅      |
| `none`     | **1**                  | `==1`         | ✅      |
| `tampered` | **1**                  | `==1`         | ✅      |

Latency on the authed path:

| Metric                                   | Value         | Threshold |
|------------------------------------------|---------------|-----------|
| `http_req_duration{auth:bearer}` p(95)   | **313.25 ms** | `< 500 ms` ✅ |

k6 exit: **0** (no thresholds crossed). Full export:
[`load-tests/results/auth-smoke.json`](../load-tests/results/auth-smoke.json).

## 3. Spring auth surface — manual cross-checks

| Probe | Command (abridged) | Status |
|------|--------------------|--------|
| Login (admin) | `POST /api/auth/login` `{admin,admin-change-me}` | `200` + `{accessToken, refreshToken, user.roles=["admin"]}` ✅ |
| Verify w/ Bearer | `GET /api/auth/verify -H "Authorization: Bearer …"` | `200` + `X-User-Id`, `X-Tenant-Id`, `X-Roles: admin` ✅ |
| Verify no header | `GET /api/auth/verify` | `401 {"message":"Missing Bearer token"}` ✅ |
| Verify bad token | `GET /api/auth/verify -H "Authorization: Bearer not.a.jwt"` | `401 {"message":"Invalid or expired token"}` ✅ |
| Refresh | `POST /api/auth/refresh {refreshToken}` | new `accessToken` (different `jti`) + rotated refresh ✅ |

## 4. UI auth wiring ✅

- `next build` clean (`agentmesh-io/agentmesh-ui@762235d`):
  16/16 static pages; `/login`, `/api/auth/{login,refresh,logout}`
  routes registered; Proxy middleware registered.
- TypeScript: `npx tsc --noEmit` clean.
- See `docs/tests/M13.2-authnz.md` H7–H8 for the manual UI probe
  (login → dashboard → token expiry → silent refresh → logout).

---

## Notes for sprint close

- Risk **R6** (AUTH_ENFORCED rollout) remains intentionally `false`
  for the dev compose stack so existing UAT/k6 lanes that pre-date
  JWT keep working until M13.3. Edge `jwt-auth@file` attachment to
  the protected routers + AUTH_ENFORCED flip will be the **first**
  M13.3 commit.
- Risk **R1** (WS query-param JWT in Traefik access logs) is
  scheduled for M13.3 hardening.

The two remaining sprint-13.2 boxes
(`OAuth2/OIDC at the Traefik edge` and the AUTH_ENFORCED flip) stay
open until they ride together in M13.3 to avoid breaking the v1.0
UAT flows mid-sprint.

