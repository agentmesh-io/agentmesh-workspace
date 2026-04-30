# 🚀 AgentMesh Platform — Release Notes v1.1.0

**Release Date:** 2026-04-30 ✅
**Code Name:** Adoption Train
**Status:** **Released** — tag `v1.1.0`
**Previous:** [v1.0.0 — Genesis](RELEASE_NOTES_v1.0.md) (2026-04-22)

---

## TL;DR

v1.0 shipped the platform. v1.1 makes the platform *adoptable*:

* **One command from a fresh clone:** `make demo` → infra + app + smoke + URLs in ~3 min.
* **Fail-closed by default:** `AUTH_ENFORCED=true`, edge `jwt-auth@docker` middleware enforces JWT before Spring sees the request.
* **Stage-aware Helm chart:** `charts/agentmesh/` with hardened dev / staging / prod overlays — NetworkPolicy with RFC1918-deny egress, PSA `restricted` namespace labels, ServiceMonitor for prom-operator, topologySpread for HA, HPA tuned to M12 load-test numbers.
* **One latent v1.0 defect found and fixed:** F2 — `MASTViolation.evidence` was `@Lob`-annotated on a Postgres `text` column, causing a non-transactional read to throw `Large Objects may not be used in auto-commit mode`, surfaced as HTTP 403. UAT back to **21/21 PASS**.

---

## Sprint M13.3 acceptance (7-of-7 commits)

| # | Commit | Subject | Risk closed / box ticked |
|---|---|---|---|
| 1 | `R6 close` | `AUTH_ENFORCED=true` Spring default + Traefik dual-router (`agentmesh-api-public` priority 100, `agentmesh-api` priority 10 with `jwt-auth@docker`) | **R6** (M13.2 deferral) |
| 2 | `F1+F2 cleanup` | Deleted dead `gateway/routes/agentmesh.yml`; F2 root-cause = JPA `@Lob` on Postgres `text`, not Spring Security RBAC; reflection regression test added | F1 + F2 |
| 3 | `Helm chart` | `charts/agentmesh/` — apiVersion v2, three stage overlays, fail-closed when `ingress.host` empty | "Helm chart … values for dev/staging/prod" |
| 4 | `Hardened K8s` | NetworkPolicy named-namespace selectors + RFC1918-deny egress; PSA labels (staging=baseline, prod=restricted); ServiceMonitor; topologySpread; HPA tuned to M12 numbers | "Hardened K8s manifests …" |
| 5 | `make demo` | Workspace `Makefile` (18 targets) + `scripts/demo-smoke.sh` (9 probes) | "make demo target …" |
| 6 | `Demo storyboard + walkthrough` | `docs/DEMO_SCRIPT_v1.1.md` (9 min 30 s, 8 scenes) + `scripts/demo-walkthrough.sh` paced tour | "Screen-recorded demo …" |
| 7 | `v1.1.0 tag` | This release | "v1.1.0 tag + GitHub release" |

**Acceptance evidence:** [`docs/ACCEPTANCE_M13.3.md`](ACCEPTANCE_M13.3.md) — every commit has its own verification matrix.

---

## What's New

### Security

* **R6 — Edge JWT enforcement.** `AUTH_ENFORCED=true` is the new Spring hard default (`SecurityConfig` `@Value` fallback flipped from `:false` to `:true`). Traefik gateway runs a dual-router pattern:
  * `agentmesh-api-public` (priority 100): bypass for `/api/auth/**`, `/actuator/health*`, `/actuator/info`, `/actuator/prometheus`, `/v3/api-docs`, `/swagger-ui`, `/ws/**`.
  * `agentmesh-api` (priority 10): `api-ratelimit, api-cors, jwt-auth@docker` middleware chain.
  * Tampered tokens are rejected at the edge (RS256 sig check via forwardAuth → `/api/auth/verify`).
* **F2 — JPA `@Lob` autocommit trap closed.** `MASTViolation.evidence` no longer carries `@Lob`. Hibernate now binds via `VarcharJdbcType` (no transaction required). Regression-test guard at `MASTViolationLobMappingTest`.
* **NetworkPolicy hardening.** Outbound 443 now uses `ipBlock cidr=0.0.0.0/0 except RFC1918` so a compromised pod cannot pivot inside the cluster via HTTPS. Ingress is namespace-pinned via `kubernetes.io/metadata.name`.
* **Pod Security Admission.** Modern replacement for the deprecated PodSecurityPolicy (gone in K8s 1.25+). Staging applies `baseline`, prod applies `restricted`. Pod template already complies with `restricted`: non-root, capDrop ALL, seccomp RuntimeDefault, no privEscalation.

### Operability

* **`make demo` end-to-end.** Single command, idempotent, 5-min wait-healthy ceiling, fail-fast on missing prereqs. 18 documented Make targets via `make help`.
* **`scripts/demo-smoke.sh` 9-probe smoke.** Public bypass + login mint + R6 enforcement + F2 regression coverage + tampered-token rejection. Runs in <2 s.
* **`docs/DEMO_SCRIPT_v1.1.md` storyboard.** 9 min 30 s recording-ready demo with beat-by-beat timing, narrator track, and `make demo-walkthrough` companion.
* **Helm chart `charts/agentmesh/`.** Three stage overlays + ServiceMonitor + topologySpread + tuned HPA. Lint + template clean for all three stages.

### Developer Experience

* `make help` is the default target.
* `make demo-clean CONFIRM=yes` env-gate prevents accidental destructive ops in CI.
* `docker-compose.yml` no longer triggers Compose v2's "obsolete `version:`" warning.
* `.gitignore` anchors fixed (`/AgentMesh/` not `AgentMesh/`) so case-insensitive macOS APFS doesn't shadow `charts/agentmesh/`.

---

## Numbers vs. v1.0 baseline

| Metric | v1.0 (M12) | **v1.1 (M13.3)** | Trend |
|---|---|---|---|
| `auth-smoke` bearer p95 | 313 ms | **20.5 ms** | 15× faster (containerised vs host process) |
| `auth-smoke` bearer fail-rate | 0 | **0** | ✅ |
| `auth-smoke` no-token reject | 1 | **1** | ✅ |
| `auth-smoke` tampered reject | 1 | **1** | ✅ |
| `load-test smoke` p95 | n/a (no auth) | **17.6 ms** | new baseline |
| `load-test smoke` errors | n/a | **0 / 1015 checks** | new baseline |
| UAT pass count | 20/20 | **21/21** | ▲ +1 (new MAST coverage) |
| `make demo` cold start | manual ~10 min | **~3 min** | new |
| `make demo` warm restart | n/a | **~30 s** | new |
| Helm lint clean stages | 0 | **3 (dev/staging/prod)** | new |
| Hardened prod manifest resources | n/a | **9** (incl. NetworkPolicy + ServiceMonitor) | new |

Sustained baseline (M12 load profile): **p95 = 12.96 ms @ 100 VUs, 222 req/s, 0 errors / 13 401 requests**. v1.1's HPA scale-up tuning (`stabilizationWindowSeconds: 15`, `selectPolicy: Max`) is calibrated against the 109 ms ramp-burst signal seen in that report.

---

## Component versions

| Component | Version | Tag commit | Highlights |
|---|---|---|---|
| **AgentMesh** | v1.1.0 | `e166b4f` (workspace alignment to v1.1) | F2 fix (drop `@Lob`), `AUTH_ENFORCED=true` default, Flyway V9/V10 stable |
| **AgentMesh-UI** | v1.1.0 | unchanged from M13.2 (`762235d`) | Already auth-aware in M13.2 — no v1.1 work needed |
| **Auto-BADS** | v1.0.0 | unchanged | No v1.1 work; `auto-bads-path` retained without `jwt-auth` (Auto-BADS doesn't consume our JWT — deferred to M14) |
| **Workspace** | v1.1.0 | `8b6cf63` (then this commit) | Helm chart + Makefile + demo storyboard + acceptance evidence |

---

## Upgrade from v1.0

Two paths.

### Compose path (the demo lane)

```sh
git -C $WORKSPACE pull --ff-only origin main
git -C $WORKSPACE/AgentMesh pull --ff-only origin main
make demo
```

`docker-compose.gateway.yml` already renders the new dual-router pattern.
The R6 default flip is a Spring-side env-var change — `AUTH_ENFORCED=true`
is now the implicit default; existing override files keep working.

### Helm path (new in v1.1)

```sh
helm upgrade --install agentmesh charts/agentmesh \
  -n agentmesh --create-namespace \
  -f charts/agentmesh/values-prod.yaml \
  --set ingress.host=api.your-domain.example \
  --set existingSecret=agentmesh-secrets   # pre-create via sealed-secrets/ESO
```

See [`charts/agentmesh/README.md`](../charts/agentmesh/README.md) for
the per-stage matrix and the HPA tuning rationale.

---

## Breaking changes

**None at the Spring/HTTP API level.**

Two operational changes worth noting:

1. **`AUTH_ENFORCED=true` is now the default.** Operators who relied on
   the M13.2 implicit `:false` default must either set
   `AUTH_ENFORCED=false` explicitly or wire bearer tokens into clients.
   Rollback is a single env-var flip — see [`docs/ACCEPTANCE_M13.3.md`](ACCEPTANCE_M13.3.md) §"Commit 1, Rollback".
2. **`gateway/routes/agentmesh.yml` deleted.** Was dead config (Traefik
   file provider only watches `gateway/dynamic/`). Anyone with
   bookmarks should update to `docker-compose.gateway.yml` labels.

---

## Known issues / deferred to M14

* `auto-bads-path` Traefik router does not yet attach `jwt-auth@docker` (Auto-BADS doesn't consume our JWT). Deferred to M14.
* OAuth2/OIDC at the Traefik edge (forwardAuth → external IdP) — placeholder in roadmap; v1.1 ships RS256 first-party JWT.
* Helm umbrella chart (Bitnami postgresql/redis/kafka subcharts) — out of scope; v1.1 chart points at existing in-cluster services.

---

## Sprint history

* **M11** — Foundation, multi-agent loop
* **M12** — Phase B hardening: Postgres, Traefik gateway, k6 load tests, UAT 20/20 → **v1.0.0 Genesis** (2026-04-22)
* **M13.1** — Auto-BADS hardening + Spring Security RBAC matrix
* **M13.2** — JWT (RS256), UI auth wiring, k6 auth-smoke green; R6 deferred
* **M13.3** — Adoption Train (this release): R6 close + Helm + hardened K8s + `make demo` → **v1.1.0**

---

## Acceptance evidence

* [`docs/ACCEPTANCE_M13.3.md`](ACCEPTANCE_M13.3.md) — 7 commits × verification matrix each
* [`docs/ROADMAP_M13.md`](ROADMAP_M13.md) — every box ticked through Sprint 13.3
* [`docs/DEMO_SCRIPT_v1.1.md`](DEMO_SCRIPT_v1.1.md) — recording storyboard
* [`charts/agentmesh/README.md`](../charts/agentmesh/README.md) — chart usage
* [`docs/LOAD_TEST_REPORT_M12.md`](LOAD_TEST_REPORT_M12.md) — referenced for HPA tuning calibration

---

🚂 **Adoption Train, departing.** Next stop: M14 (OAuth2/OIDC + Auto-BADS edge auth).

