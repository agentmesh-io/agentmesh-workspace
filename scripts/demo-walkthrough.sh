#!/usr/bin/env bash
# =============================================================================
# scripts/demo-walkthrough.sh
#
# Paced, narrator-friendly walkthrough of the v1.1 demo beats. Mirrors the
# storyboard in docs/DEMO_SCRIPT_v1.1.md (§1 - §6). Use for live recording
# (`make demo-walkthrough`) or as a self-running tour for reviewers.
#
# Assumes `make demo` has already brought the stack up. Doesn't tear down.
# =============================================================================
set -euo pipefail

HOST_API=${HOST_API:-api.agentmesh.localhost}
ADMIN_USER=${ADMIN_USER:-admin}
ADMIN_PASS=${ADMIN_PASS:-admin-change-me}
PAUSE=${PAUSE:-3}      # seconds between beats — override with PAUSE=1 for fast preview

CYAN='\033[1;36m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; DIM='\033[2m'; RESET='\033[0m'

beat () {
  printf "\n${CYAN}══ %s ══════════════════════════════════════════${RESET}\n" "$1"
  sleep 1
}
say () { printf "${YELLOW}# %s${RESET}\n" "$1"; sleep "$PAUSE"; }
run () { printf "${DIM}\$ %s${RESET}\n" "$*"; eval "$@" || true; sleep "$PAUSE"; }

# ─── beat 1 ──────────────────────────────────────────────────────────────────
beat "Hook — clone, one command"
say "AgentMesh v1.1 — the Adoption Train. Single-command demo, fail-closed,"
say "stage-aware Helm chart. Watch."
run "make help | head -20"

# ─── beat 2 ──────────────────────────────────────────────────────────────────
beat "Live status (assume make demo already ran)"
run "make demo-status"

# ─── beat 3 ──────────────────────────────────────────────────────────────────
beat "R6 close — Spring fails closed by default"
say "No-token request. Edge enforcement via Traefik forwardAuth (jwt-auth@docker)."
run "curl -sS -o /dev/null -w 'HTTP %{http_code}\\n' \
     -H 'Host: $HOST_API' http://localhost/api/workflows"

say "Mint a token via the public-bypass router."
TOKEN=$(curl -sS -H "Host: $HOST_API" -H 'Content-Type: application/json' \
  -X POST http://localhost/api/auth/login \
  -d "{\"username\":\"$ADMIN_USER\",\"password\":\"$ADMIN_PASS\"}" \
  | sed -n 's/.*"accessToken":"\([^"]*\)".*/\1/p')
printf "${GREEN}token chars: %d  (RS256, 15-min TTL)${RESET}\n" "${#TOKEN}"
sleep "$PAUSE"

say "Same workflows call, with bearer."
run "curl -sS -o /dev/null -w 'HTTP %{http_code}\\n' \
     -H 'Host: $HOST_API' -H 'Authorization: Bearer $TOKEN' \
     http://localhost/api/workflows"

# ─── beat 4 ──────────────────────────────────────────────────────────────────
beat "F2 fix — MAST violations endpoint (was 403, now 200)"
say "M13.3 c1 found /api/mast/violations/recent reproducibly returning 403."
say "Root cause: JPA @Lob on a Postgres text column → Hibernate ClobJdbcType →"
say "  PSQLException 'Large Objects may not be used in auto-commit mode' →"
say "  Spring exception path surfaced it as HTTP 403, masquerading as RBAC."
say "One annotation removed, reflection regression test added, UAT 21/21."
run "curl -sS -o /dev/null -w 'HTTP %{http_code}\\n' \
     -H 'Host: $HOST_API' -H 'Authorization: Bearer $TOKEN' \
     http://localhost/api/mast/violations/recent"
run "curl -sS -o /dev/null -w 'HTTP %{http_code}\\n' \
     -H 'Host: $HOST_API' -H 'Authorization: Bearer $TOKEN' \
     http://localhost/api/mast/violations/unresolved"

# ─── beat 5 ──────────────────────────────────────────────────────────────────
beat "Smoke probe — 9 checks in under 2 seconds"
run "bash scripts/demo-smoke.sh"

# ─── beat 6 ──────────────────────────────────────────────────────────────────
beat "Multi-stage Helm chart"
say "Three profiles: dev / staging / prod. All lint clean."
run "make helm-lint 2>&1 | grep -E '^(==>|1 chart)' | head -10"

say "Prod render — 9 resources including NetworkPolicy with RFC1918-deny egress."
run "helm template demo charts/agentmesh -n agentmesh \
     -f charts/agentmesh/values-prod.yaml \
     | grep -E '^kind:' | sort -u"

say "Confirm RFC1918-deny egress rule on TCP 443:"
run "helm template demo charts/agentmesh -n agentmesh \
     -f charts/agentmesh/values-prod.yaml \
     | sed -n '/kind: NetworkPolicy/,/^---/p' \
     | grep -A 5 'ipBlock:'"

# ─── beat 7 ──────────────────────────────────────────────────────────────────
beat "Wrap"
say "v1.1 ships next: tag, GitHub release, Helm chart, hardened manifests,"
say "make demo, F2 fix, R6 close. See docs/RELEASE_NOTES_v1.1.md."
printf "\n${GREEN}walkthrough complete${RESET}\n"


