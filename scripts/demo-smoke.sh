#!/usr/bin/env bash
# =============================================================================
# scripts/demo-smoke.sh
#
# End-to-end smoke probe for the workspace `make demo` target. Verifies that
# the public-bypass router, JWT auth path, and a representative protected
# endpoint all work — without spinning up the full UAT (test-scripts/uat-full-flow-v1.sh).
#
# Exit 0 = all probes passed. Non-zero on first failure.
# =============================================================================
set -euo pipefail

HOST_API=${HOST_API:-api.agentmesh.localhost}
ADMIN_USER=${ADMIN_USER:-admin}
ADMIN_PASS=${ADMIN_PASS:-admin-change-me}
BASE="http://localhost"

CYAN='\033[1;36m'; GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; RESET='\033[0m'
PASS=0; FAIL=0

probe () {
  local label="$1" expected="$2"; shift 2
  local actual
  actual=$(curl -sS -o /dev/null -w '%{http_code}' "$@" || echo "000")
  if [[ "$actual" == "$expected" ]]; then
    printf "  ${GREEN}✓${RESET} %-46s expected=%s actual=%s\n" "$label" "$expected" "$actual"
    PASS=$((PASS+1))
  else
    printf "  ${RED}✗${RESET} %-46s expected=%s actual=%s\n" "$label" "$expected" "$actual"
    FAIL=$((FAIL+1))
  fi
}

printf "${CYAN}══ AgentMesh demo smoke ══════════════════════════════${RESET}\n"

# ─── 1. public bypass (no token expected) ────────────────────────────────────
probe "actuator/health (public bypass)"      200 -H "Host: $HOST_API" "$BASE/actuator/health"
probe "actuator/prometheus (public bypass)"  200 -H "Host: $HOST_API" "$BASE/actuator/prometheus"

# ─── 2. login → token (login itself is public) ───────────────────────────────
LOGIN_PAYLOAD=$(printf '{"username":"%s","password":"%s"}' "$ADMIN_USER" "$ADMIN_PASS")
LOGIN_BODY=$(curl -sS -H "Host: $HOST_API" -H 'Content-Type: application/json' \
  -X POST "$BASE/api/auth/login" -d "$LOGIN_PAYLOAD" || true)
TOKEN=$(printf '%s' "$LOGIN_BODY" | sed -n 's/.*"accessToken":"\([^"]*\)".*/\1/p')
if [[ -n "$TOKEN" && ${#TOKEN} -gt 100 ]]; then
  printf "  ${GREEN}✓${RESET} %-46s token_chars=%s\n" "POST /api/auth/login" "${#TOKEN}"
  PASS=$((PASS+1))
else
  printf "  ${RED}✗${RESET} %-46s body=%s\n" "POST /api/auth/login" "$LOGIN_BODY"
  FAIL=$((FAIL+1))
  TOKEN=""
fi

# ─── 3. R6 enforcement (no-token → 401) ──────────────────────────────────────
probe "GET /api/workflows  (no token, expect 401)" 401 -H "Host: $HOST_API" "$BASE/api/workflows"

# ─── 4. authenticated reads ──────────────────────────────────────────────────
if [[ -n "$TOKEN" ]]; then
  AUTH=( -H "Host: $HOST_API" -H "Authorization: Bearer $TOKEN" )
  probe "GET /api/workflows  (authed)"               200 "${AUTH[@]}" "$BASE/api/workflows"
  probe "GET /api/mast/violations/recent  (F2)"      200 "${AUTH[@]}" "$BASE/api/mast/violations/recent"
  probe "GET /api/mast/violations/unresolved (F2)"   200 "${AUTH[@]}" "$BASE/api/mast/violations/unresolved"
  probe "GET /api/mast/failure-modes"                 200 "${AUTH[@]}" "$BASE/api/mast/failure-modes"
fi

# ─── 5. tampered token → 401 ─────────────────────────────────────────────────
if [[ -n "$TOKEN" ]]; then
  TAMPERED="${TOKEN%???}xxx"
  probe "GET /api/workflows  (tampered token, 401)"  401 -H "Host: $HOST_API" -H "Authorization: Bearer $TAMPERED" "$BASE/api/workflows"
fi

printf "\n${CYAN}── Result ──${RESET}  PASS=%d  FAIL=%d\n" "$PASS" "$FAIL"
if [[ $FAIL -ne 0 ]]; then
  printf "${RED}smoke failed — see 'make demo-logs'${RESET}\n"
  exit 1
fi
printf "${GREEN}✓ all smoke probes passed${RESET}\n"

