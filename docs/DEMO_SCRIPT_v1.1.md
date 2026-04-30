# 🎬 AgentMesh v1.1 — Demo Script & Storyboard

**Target runtime:** 9 minutes 30 seconds (≤ 10 min gate per ROADMAP_M13.md)
**Audience:** Engineering supervisor / external reviewer
**Recording mode:** ZSH terminal at 14pt, dark theme, full-screen.
**Companion target:** `make demo-walkthrough` runs the same beats with paced output for live recording.

> This is the **shipping demo for v1.1.0** (Architect Protocol §4 sprint demo, M13.3 commit 6).
> v1.0 told the story *"idea → SRS → code"*. v1.1 tells the story *"clone → demo → ship"*: the platform itself is now self-installing, fail-closed, and stage-aware.

---

## 0. Pre-flight (off camera, t = −2 min)

```sh
# Reset to a clean state so the demo records the cold-start path
make demo-clean CONFIRM=yes
docker system prune -f >/dev/null
clear
```

Optional: open a second pane with `docker stats` to make CPU/memory live.

---

## 1. Hook — *"clone, type one command, watch v1.1 stand up"* (00:00 – 00:30)

**Narrator (~25 s):**
> "AgentMesh v1.0 shipped in M12 — agent orchestration, MAST, multi-tenancy, k6 p95 of 12 ms. v1.1 — the **Adoption Train** — is about getting that platform into other people's hands. One command, fail-closed defaults, stage-aware Helm chart, hardened manifests."

**Show:**

```sh
git clone git@github.com:agentmesh-io/agentmesh-workspace.git
cd agentmesh-workspace
make help            # ← 17 documented targets, default goal
```

Expected output: green-cyan menu with `demo`, `demo-down`, `helm-lint`, etc.

---

## 2. The single command (00:30 – 03:30, ~3 min)

**Narrator (~10 s):**
> "Watch this. Single command, idempotent, fail-fast on missing prereqs."

```sh
make demo
```

Beat-by-beat what the audience sees:

| Beat | Time | Visual |
|---|---|---|
| `prereqs` check | 00:32 | `✓ prereqs OK` (green) |
| Shared infra up | 00:35 → 00:50 | `dev-postgres`, `dev-redis` Started |
| App stack build | 00:50 → 02:30 | `--build` for `agentmesh-api`, `agentmesh-ui`, `auto-bads`, `traefik` |
| `wait-healthy` polling | 02:30 → 03:00 | `[ 1/60] waiting (status=pending)…` ramping to `✓ agentmesh-api is UP (after 6×5s)` |
| `demo-smoke` 9 probes | 03:00 → 03:05 | Green checkmarks, `PASS=9 FAIL=0` |
| `demo-urls` | 03:05 → 03:15 | Operator URLs + login creds printed |

**Talk track during the build (~2 min):**
> "While that builds — what just happened. Compose v2 brought up the shared `global-infra` network, then the application stack: Traefik gateway, the Spring Modulith API, the Next.js UI, Auto-BADS. A 5-minute wait-healthy ceiling polls `/actuator/health` until Spring reports `UP`. Then a 9-probe smoke runs — public bypass, login mint, R6 enforcement (no-token = 401), authenticated reads, MAST violations, tampered-token rejection. If any of those fail, the make recipe exits non-zero — no silent partial bring-up."

---

## 3. Open the UI (03:30 – 04:30, ~1 min)

**Switch to browser. Three tabs ready:**

```
http://app.agentmesh.localhost/
http://api.agentmesh.localhost/actuator/prometheus
http://traefik.agentmesh.localhost/dashboard/
```

**Beats:**
1. `app.agentmesh.localhost` → login screen renders.
2. Login as `admin / admin-change-me`.
3. Dashboard renders with WS frame visible in DevTools network tab (`?token=…` confirms M13.2 auth wiring).
4. Prometheus tab shows live JVM + HTTP metrics (proves the public-bypass router from M13.3 c1).
5. Traefik dashboard shows two routers — `agentmesh-api-public` (priority 100) and `agentmesh-api` (priority 10, with `jwt-auth@docker` middleware). This is **R6 in production**.

---

## 4. R6 close + F2 fix — security story (04:30 – 06:00, ~1.5 min)

**Switch back to terminal.**

```sh
# 4a. R6 — Spring fails closed; no-token request returns 401 at the EDGE
curl -i -H "Host: api.agentmesh.localhost" http://localhost/api/workflows | head -3
# HTTP/1.1 401 Unauthorized

# 4b. R6 — login (public-bypass router, NO jwt-auth middleware)
TOKEN=$(curl -sS -H "Host: api.agentmesh.localhost" -H 'Content-Type: application/json' \
  -X POST http://localhost/api/auth/login \
  -d '{"username":"admin","password":"admin-change-me"}' \
  | jq -r .accessToken)
echo "Token: ${TOKEN:0:60}…"   # 721-char RS256

# 4c. Same call, with token: 200
curl -s -H "Host: api.agentmesh.localhost" -H "Authorization: Bearer $TOKEN" \
  http://localhost/api/workflows | jq '. | length'

# 4d. F2 — MAST endpoint that was reproducibly 403 in c1 acceptance run
curl -s -o /dev/null -w '%{http_code}\n' \
  -H "Host: api.agentmesh.localhost" -H "Authorization: Bearer $TOKEN" \
  http://localhost/api/mast/violations/recent
# 200
```

**Narrator:**
> "Three things here. Edge enforcement — Traefik's forwardAuth middleware rejects the no-token request before Spring even sees it. JWT mint — RS256, keys on the Blackhole SSD. And the F2 fix — `/api/mast/violations/recent` was reproducibly 403 in the M13.3 commit 1 acceptance run; root cause turned out to be a JPA `@Lob` annotation on a PostgreSQL `text` column, not Spring Security at all. Hibernate routed the read through `LargeObjectManager` which threw outside a transaction, and Spring surfaced it as 403. One annotation removed, one reflection regression test added, UAT 21 of 21 PASS."

---

## 5. Multi-stage Helm chart (06:00 – 07:30, ~1.5 min)

```sh
make helm-lint                                 # 0 chart(s) failed × 3 stages
helm template demo charts/agentmesh -n agentmesh \
  -f charts/agentmesh/values-prod.yaml | grep -E "^kind:" | sort -u
```

**Expected:**
```
kind: ConfigMap
kind: Deployment
kind: HorizontalPodAutoscaler
kind: Ingress
kind: NetworkPolicy
kind: PodDisruptionBudget
kind: Service
kind: ServiceAccount
kind: ServiceMonitor
```

**Show key prod renders:**

```sh
helm template demo charts/agentmesh -n agentmesh \
  -f charts/agentmesh/values-prod.yaml \
  | sed -n '/^kind: NetworkPolicy/,/^---/p' \
  | grep -A 4 'ipBlock:'
```

**Expected:**
```
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
              - 10.0.0.0/8
              - 172.16.0.0/12
              - 192.168.0.0/16
```

**Narrator:**
> "Stage-aware Helm chart, three profiles — `dev`, `staging`, `prod`. Prod gets HPA tuned to our M12 load-test numbers — scale-up window 15 seconds because we measured a 109 ms ramp burst, scale-down kept slow at 5 minutes for LLM tail latency. NetworkPolicy denies RFC1918 on outbound 443 — a compromised pod can't pivot inside the cluster. ServiceMonitor for prom-operator. PSA `restricted` namespace labels. Topology spread across zones and hostnames."

---

## 6. Tear-down + idempotence (07:30 – 08:30, ~1 min)

```sh
make demo-down       # volumes preserved
make demo-status     # shows containers stopped
make demo            # idempotent — reuses cached layers, ~30 s cold restart
```

**Narrator:**
> "Demo-down is non-destructive — volumes preserved. Demo-clean with CONFIRM equals yes is the destructive path; environment-variable gate, not a flag, so it can never accidentally trigger in CI. And the whole thing is idempotent — same command brings it back in 30 seconds because Compose layer cache is warm."

---

## 7. The numbers slide (08:30 – 09:15, ~45 s)

**Switch to a static slide / `cat` a small markdown file:**

| Metric | M13.2 baseline | M13.3 final |
|---|---|---|
| `auth-smoke` bearer p95 | 313 ms | **20.5 ms** (15× faster) |
| `load-test smoke` p95 | n/a | **17.6 ms** (1015/1015 checks pass) |
| UAT pass count | 20/20 | **21/21** |
| `make demo` cold start | manual ~10 min | **~3 min** |
| `make demo` warm restart | n/a | **~30 s** |
| Helm lint clean stages | 0 | **3** (dev/staging/prod) |
| Hardened manifests resources (prod render) | n/a | **9** incl. NetworkPolicy + ServiceMonitor |

---

## 8. Wrap (09:15 – 09:30, ~15 s)

> "v1.1 — the Adoption Train. Tag's getting cut next, see you in v1.2."

**Stop recording.** Save raw to `~/Desktop/agentmesh-v1.1-demo.mov`.

---

## Operator checklist (during recording)

- [ ] Terminal font size ≥ 14pt
- [ ] Window title hidden / clean prompt (`PS1='$ '` for the demo)
- [ ] Browser at 100% zoom; no extension chrome visible
- [ ] DevTools open in network tab for the WS frame visual
- [ ] Mic input level checked (peak around -12 dB)
- [ ] Demo-clean run beforehand
- [ ] LMStudio paused (avoids GPU fan noise on the recording)

## Reproducibility

Anyone with this repo cloned can re-run the technical beats verbatim:

```sh
make demo-walkthrough     # narrator-paced, no recording assumed
```

The `demo-walkthrough` target reproduces beats §1 → §6 with `sleep`-driven
pacing so an operator can hit Record and let it run.

