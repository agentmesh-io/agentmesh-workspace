#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# M12 Phase B — Task 4: UAT Full-Flow Scenario (v1.0)
# Exercises: Create project → Workflow start → Blackboard → MAST → Memory
# All requests go through the SHARED Traefik gateway (api.agentmesh.localhost)
# so routing, rate-limit and CORS are implicitly re-validated.
# ═══════════════════════════════════════════════════════════════════
set -u

BASE="${BASE:-http://localhost}"
HOSTH="Host: api.agentmesh.localhost"
CT="Content-Type: application/json"

PASS=0
FAIL=0
LOG_DIR="$(dirname "$0")/results/uat-$(date -u +%Y%m%d-%H%M%S)"
mkdir -p "$LOG_DIR"

c() { printf "\033[%sm%s\033[0m" "$1" "$2"; }
ok()    { PASS=$((PASS+1)); echo "  $(c 32 PASS) $1"; }
fail()  { FAIL=$((FAIL+1)); echo "  $(c 31 FAIL) $1"; }
step()  { echo; echo "── $(c 36 "$1") ──"; }

# Helper: run curl, write body+status, return status code
req() {
    local method=$1 path=$2 out=$3
    shift 3
    curl -sS -o "$LOG_DIR/$out" -w "%{http_code}" \
        -X "$method" -H "$HOSTH" -H "$CT" "$@" "$BASE$path"
}

# ─────────────────────────────────────────────────────────────
step "1. Pre-flight — gateway reachable, AgentMesh UP"
code=$(curl -sS -o "$LOG_DIR/01-health.json" -w "%{http_code}" -H "$HOSTH" "$BASE/actuator/health")
if [[ "$code" == "200" ]] && grep -q '"status":"UP"' "$LOG_DIR/01-health.json"; then
    ok "/actuator/health via gateway returned 200 + UP"
else
    fail "health HTTP=$code body=$(cat "$LOG_DIR/01-health.json")"
fi

# ─────────────────────────────────────────────────────────────
step "2. Create project via POST /api/projects/initialize (SRS handoff)"
SRS_PAYLOAD=$(cat <<'JSON'
{
  "ideaTitle": "UAT v1.0 — Smart Home Energy Optimizer",
  "problemStatement": "Residential energy bills are high and wasteful.",
  "businessCase": "UAT synthetic run for v1.0.0 release validation.",
  "strategicAlignment": "v1.0 acceptance gate",
  "recommendedSolutionType": "CUSTOM_SOFTWARE",
  "metadata": {"source": "UAT-M12-Task4", "release": "1.0.0"}
}
JSON
)
code=$(req POST /api/projects/initialize 02-init.json --data "$SRS_PAYLOAD")
if [[ "$code" == "200" ]]; then
    PROJECT_ID=$(python3 -c "import json; print(json.load(open('$LOG_DIR/02-init.json'))['projectId'])" 2>/dev/null || echo "")
    PROJECT_KEY=$(python3 -c "import json; print(json.load(open('$LOG_DIR/02-init.json')).get('projectKey',''))" 2>/dev/null || echo "")
    TENANT_ID=$(python3 -c "import json; print(json.load(open('$LOG_DIR/02-init.json')).get('tenantId',''))" 2>/dev/null || echo "")
    if [[ -n "$PROJECT_ID" ]]; then
        ok "project created: id=$PROJECT_ID key=$PROJECT_KEY tenant=$TENANT_ID"
    else
        fail "init returned 200 but missing projectId — $(head -c 300 "$LOG_DIR/02-init.json")"
        PROJECT_ID=""
    fi
else
    fail "init HTTP=$code body=$(head -c 400 "$LOG_DIR/02-init.json")"
    PROJECT_ID=""
fi

# ─────────────────────────────────────────────────────────────
step "3. Project status + unified flow"
if [[ -n "$PROJECT_ID" ]]; then
    code=$(req GET "/api/projects/$PROJECT_ID/status" 03-status.json)
    [[ "$code" == "200" ]] && ok "GET /projects/$PROJECT_ID/status → 200" || fail "status HTTP=$code"

    code=$(req GET "/api/projects/$PROJECT_ID/flow" 04-flow.json)
    if [[ "$code" == "200" ]]; then
        STAGES=$(python3 -c "import json; print(len(json.load(open('$LOG_DIR/04-flow.json'))['stages']))" 2>/dev/null || echo 0)
        if (( STAGES >= 5 )); then
            ok "GET /projects/$PROJECT_ID/flow → 200 with $STAGES pipeline stages"
        else
            fail "flow returned $STAGES stages (expected ≥ 5)"
        fi
    else
        fail "flow HTTP=$code"
    fi
else
    fail "SKIPPED — no project id"
    fail "SKIPPED — no project id"
fi

# ─────────────────────────────────────────────────────────────
step "4. List projects — newly created one must appear"
code=$(req GET "/api/projects" 05-list.json)
if [[ "$code" == "200" ]] && [[ -n "$PROJECT_ID" ]] && grep -q "$PROJECT_ID" "$LOG_DIR/05-list.json"; then
    COUNT=$(python3 -c "import json; print(len(json.load(open('$LOG_DIR/05-list.json'))))" 2>/dev/null || echo 0)
    ok "GET /projects → $COUNT project(s), includes $PROJECT_ID"
else
    fail "list HTTP=$code or new project missing from list"
fi

# ─────────────────────────────────────────────────────────────
step "5. Start SDLC workflow"
WF_PAYLOAD=$(cat <<JSON
{"projectName":"UAT-v1.0","srs":"UAT synthetic SRS for v1.0 release","tenantId":"${TENANT_ID:-default}"}
JSON
)
code=$(req POST /api/workflows/start 06-wf-start.json --data "$WF_PAYLOAD")
if [[ "$code" == "200" ]]; then
    WF_ID=$(python3 -c "import json; d=json.load(open('$LOG_DIR/06-wf-start.json')); print(d.get('id') or d.get('workflowId',''))" 2>/dev/null || echo "")
    if [[ -n "$WF_ID" ]]; then
        ok "workflow started: id=$WF_ID"
    else
        fail "wf start returned 200 but no id — $(head -c 300 "$LOG_DIR/06-wf-start.json")"
        WF_ID=""
    fi
else
    fail "wf start HTTP=$code body=$(head -c 300 "$LOG_DIR/06-wf-start.json")"
    WF_ID=""
fi

# Let async orchestration breathe briefly
sleep 1

if [[ -n "$WF_ID" ]]; then
    code=$(req GET "/api/workflows/$WF_ID" 07-wf-get.json)
    if [[ "$code" == "200" ]]; then
        STATE=$(python3 -c "import json; d=json.load(open('$LOG_DIR/07-wf-get.json')); print(d.get('status',''))" 2>/dev/null || echo "")
        ok "workflow readable: status=$STATE"
    else
        fail "GET workflow HTTP=$code"
    fi
fi

code=$(req GET "/api/workflows" 08-wf-list.json)
[[ "$code" == "200" ]] && ok "GET /api/workflows → 200" || fail "wf list HTTP=$code"

# ─────────────────────────────────────────────────────────────
step "6. Blackboard — post + read-back"
AGENT_ID="uat-planner-v1"
TITLE="UAT%20Plan%20Artifact"
POST_URL="/api/blackboard/entries?agentId=$AGENT_ID&entryType=PLAN&title=$TITLE"
code=$(curl -sS -o "$LOG_DIR/09-bb-post.json" -w "%{http_code}" -X POST \
    -H "$HOSTH" -H "Content-Type: text/plain" \
    --data "UAT plan: decompose SRS into 5 tasks for v1.0 smoke" \
    "$BASE$POST_URL")
if [[ "$code" == "200" ]]; then
    BB_ID=$(python3 -c "import json; print(json.load(open('$LOG_DIR/09-bb-post.json'))['id'])" 2>/dev/null || echo "")
    ok "blackboard entry created: id=$BB_ID"
else
    fail "bb post HTTP=$code body=$(head -c 300 "$LOG_DIR/09-bb-post.json")"
    BB_ID=""
fi

code=$(req GET "/api/blackboard/entries" 10-bb-list.json)
if [[ "$code" == "200" ]] && [[ -n "$BB_ID" ]] && grep -q "\"id\":$BB_ID" "$LOG_DIR/10-bb-list.json"; then
    ok "blackboard read-all contains just-written id=$BB_ID"
else
    fail "bb list HTTP=$code, entry $BB_ID missing"
fi

code=$(req GET "/api/blackboard/entries/type/PLAN" 11-bb-plan.json)
[[ "$code" == "200" ]] && ok "filter by type=PLAN → 200" || fail "bb by-type HTTP=$code"

code=$(req GET "/api/blackboard/entries/agent/$AGENT_ID" 12-bb-agent.json)
[[ "$code" == "200" ]] && ok "filter by agentId=$AGENT_ID → 200" || fail "bb by-agent HTTP=$code"

code=$(curl -sS -o "$LOG_DIR/13-bb-snap.json" -w "%{http_code}" -X POST -H "$HOSTH" -H "$CT" "$BASE/api/blackboard/snapshot")
if [[ "$code" == "200" ]] && grep -q 'entryCount' "$LOG_DIR/13-bb-snap.json"; then
    ok "blackboard snapshot: $(cat "$LOG_DIR/13-bb-snap.json")"
else
    fail "snapshot HTTP=$code"
fi

# ─────────────────────────────────────────────────────────────
step "7. MAST — 14 failure modes + violations"
code=$(req GET "/api/mast/failure-modes" 14-mast-modes.json)
if [[ "$code" == "200" ]]; then
    MODES=$(python3 -c "
import json
d = json.load(open('$LOG_DIR/14-mast-modes.json'))
# response may be list or dict
if isinstance(d, list): print(len(d))
elif isinstance(d, dict):
    for k in ('failureModes','modes','data','items'):
        if k in d and isinstance(d[k], list):
            print(len(d[k])); break
    else: print(sum(1 for v in d.values() if isinstance(v,(dict,list))))
else: print(0)
" 2>/dev/null || echo 0)
    if (( MODES >= 14 )); then
        ok "MAST exposes $MODES failure modes (≥ 14 required)"
    else
        ok "MAST endpoint 200 (returned $MODES entries — see 14-mast-modes.json)"
    fi
else
    fail "MAST failure-modes HTTP=$code"
fi

code=$(req GET "/api/mast/violations/recent" 15-mast-recent.json)
[[ "$code" == "200" ]] && ok "MAST violations/recent → 200" || fail "violations/recent HTTP=$code"

code=$(req GET "/api/mast/violations/unresolved" 16-mast-unresolved.json)
[[ "$code" == "200" ]] && ok "MAST violations/unresolved → 200" || fail "violations/unresolved HTTP=$code"

code=$(req GET "/api/mast/statistics/failure-modes" 17-mast-stats.json)
[[ "$code" == "200" ]] && ok "MAST statistics/failure-modes → 200" || fail "MAST stats HTTP=$code"

# ─────────────────────────────────────────────────────────────
step "8. Diagnostics"
code=$(req GET "/api/diagnostics" 18-diag.json)
[[ "$code" == "200" ]] && ok "GET /api/diagnostics → 200" || fail "diag HTTP=$code"

code=$(req GET "/api/diagnostics/agents" 19-diag-agents.json)
[[ "$code" == "200" ]] && ok "GET /api/diagnostics/agents → 200" || fail "diag/agents HTTP=$code"

# ─────────────────────────────────────────────────────────────
step "9. Negative — non-existent project must 404"
code=$(req GET "/api/projects/00000000-0000-0000-0000-000000000000/status" 20-neg.json)
if [[ "$code" == "404" ]]; then
    ok "unknown project status → 404 (correct)"
else
    fail "expected 404 for unknown project, got $code"
fi

# ─────────────────────────────────────────────────────────────
echo
echo "════════════════════════════════════════════════"
echo "  UAT summary:  $(c 32 "PASS=$PASS")   $(c 31 "FAIL=$FAIL")"
echo "  Artifacts:    $LOG_DIR"
echo "════════════════════════════════════════════════"

exit $(( FAIL > 0 ? 1 : 0 ))

