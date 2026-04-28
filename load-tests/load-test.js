import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const projectInitDuration = new Trend('project_init_duration', true);

// ─── Test Profiles ──────────────────────────────────────────────
// Run with: k6 run --env PROFILE=smoke load-test.js
const profiles = {
  smoke: {
    stages: [
      { duration: '10s', target: 5 },
      { duration: '20s', target: 5 },
      { duration: '10s', target: 0 },
    ],
    thresholds: {
      http_req_duration: ['p(95)<1000'],
      errors: ['rate<0.05'],
    },
  },
  load: {
    stages: [
      { duration: '15s', target: 50 },
      { duration: '30s', target: 100 },
      { duration: '15s', target: 0 },
    ],
    thresholds: {
      http_req_duration: ['p(95)<500'],
      errors: ['rate<0.01'],
    },
  },
  stress: {
    stages: [
      { duration: '20s', target: 100 },
      { duration: '40s', target: 500 },
      { duration: '30s', target: 500 },
      { duration: '30s', target: 0 },
    ],
    thresholds: {
      http_req_duration: ['p(95)<2000'],
      errors: ['rate<0.10'],
    },
  },
};

const profile = profiles[__ENV.PROFILE || 'smoke'];

export const options = {
  stages: profile.stages,
  thresholds: {
    ...profile.thresholds,
    http_req_failed: ['rate<0.05'],
  },
};

// ─── Configuration ──────────────────────────────────────────────
const AGENTMESH_URL = __ENV.AGENTMESH_URL || 'http://localhost:8081';
const AUTOBADS_URL = __ENV.AUTOBADS_URL || 'http://localhost:8083';
// Auto-BADS is an optional downstream service. Set SKIP_AUTOBADS=1 to
// bench AgentMesh in isolation (default behaviour for v1.0 release tests).
const SKIP_AUTOBADS = __ENV.SKIP_AUTOBADS === '1' || __ENV.SKIP_AUTOBADS === 'true';
// /api/projects/initialize triggers a full async workflow (GitHub export,
// event publishing, LLM calls). Only include under WORKFLOW_LOAD=1.
const WORKFLOW_LOAD = __ENV.WORKFLOW_LOAD === '1' || __ENV.WORKFLOW_LOAD === 'true';

// M13.3 commit 1 (R6 close): protected endpoints (/api/projects, /api/workflows,
// /actuator/prometheus) now require a Bearer token in production. setup() mints
// one via /api/auth/login; default() threads it via authedHeaders(data).
const USERNAME = __ENV.USERNAME || 'admin';
const PASSWORD = __ENV.PASSWORD || 'admin-change-me';

const headers = {
  'Content-Type': 'application/json',
};

// setup() runs once per test, before VUs ramp up. The returned object is
// passed as the first argument to default() and teardown().
export function setup() {
  const loginRes = http.post(
    `${AGENTMESH_URL}/api/auth/login`,
    JSON.stringify({ username: USERNAME, password: PASSWORD }),
    { headers, tags: { phase: 'setup' } }
  );
  if (loginRes.status !== 200) {
    throw new Error(
      `setup(): /api/auth/login expected 200, got ${loginRes.status} body=${loginRes.body}`
    );
  }
  const accessToken = loginRes.json('accessToken') || loginRes.json('access_token');
  if (!accessToken) {
    throw new Error(`setup(): login response missing accessToken — body=${loginRes.body}`);
  }
  console.log(`[setup] minted access token (len=${accessToken.length}) for ${USERNAME}`);
  return { accessToken };
}

// Header builder that merges Content-Type with the bearer minted in setup().
function authedHeaders(data) {
  return {
    ...headers,
    Authorization: `Bearer ${data.accessToken}`,
  };
}

// ─── Scenarios ──────────────────────────────────────────────────
// Helper: record the outcome of a group's checks as a proper rate metric
// (add(true) increments passes, add(false) increments fails — gives real % rate).
function record(ok) {
  errorRate.add(!ok);
  return ok;
}

export default function (data) {
  // Header-less probe — proves the public-bypass router (priority 100)
  // shadows /actuator/health past `jwt-auth@file`. Do NOT add Authorization here.
  group('AgentMesh Health', () => {
    const res = http.get(`${AGENTMESH_URL}/actuator/health`);
    record(check(res, {
      'AgentMesh health status 200': (r) => r.status === 200,
      'AgentMesh health body contains UP': (r) => r.body && r.body.includes('UP'),
    }));
  });

  group('AgentMesh Project Initialize', () => {
    if (!WORKFLOW_LOAD) return; // skip heavy async workflow in smoke/load

    const payload = JSON.stringify({
      // Direct SRS format accepted by ProjectController.extractSrsHandoff()
      ideaTitle: `LoadTest-Project-${__VU}-${__ITER}`,
      problemStatement: `Load test SRS from VU ${__VU} iteration ${__ITER}`,
      businessCase: 'k6 workflow profile synthetic traffic',
      recommendedSolutionType: 'CUSTOM_SOFTWARE',
    });

    const res = http.post(`${AGENTMESH_URL}/api/projects/initialize`, payload,
      { headers: authedHeaders(data), timeout: '30s' });
    projectInitDuration.add(res.timings.duration);

    record(check(res, {
      'Project init status 200 or 201': (r) => r.status === 200 || r.status === 201,
      'Project init response has body': (r) => r.body && r.body.length > 0,
    }));
  });

  group('AgentMesh Project List', () => {
    const res = http.get(`${AGENTMESH_URL}/api/projects`, { headers: authedHeaders(data) });
    record(check(res, {
      'Project list 200': (r) => r.status === 200,
    }));
  });

  group('AgentMesh Metrics', () => {
    // /actuator/prometheus stays in the public allow-list (Spring side) so
    // scrapers don't need a Bearer; sending one is harmless but we keep
    // this header-less to mirror real Prometheus behaviour.
    const res = http.get(`${AGENTMESH_URL}/actuator/prometheus`);
    record(check(res, {
      'Prometheus metrics 200': (r) => r.status === 200,
      'Metrics contain JVM info': (r) => r.body && r.body.includes('jvm_'),
    }));
  });

  if (!SKIP_AUTOBADS) {
    group('Auto-BADS Health', () => {
      const res = http.get(`${AUTOBADS_URL}/actuator/health`);
      record(check(res, {
        'Auto-BADS health status 200': (r) => r.status === 200,
      }));
    });
  }

  sleep(0.5 + Math.random() * 0.5); // 0.5–1s think time
}

// ─── Summary ──────────────────────────────────────────────────
export function handleSummary(data) {
  const now = new Date().toISOString().replace(/[:.]/g, '-');
  const outDir = __ENV.RESULTS_DIR || 'load-tests/results';
  return {
    [`${outDir}/summary-${__ENV.PROFILE || 'smoke'}-${now}.json`]: JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}

function textSummary(data, opts) {
  // k6 built-in text summary fallback
  let summary = '\n═══ Load Test Summary ═══\n';
  if (data.metrics) {
    for (const [name, metric] of Object.entries(data.metrics)) {
      if (metric.values && metric.values.avg !== undefined) {
        summary += `  ${name}: avg=${metric.values.avg.toFixed(2)}ms p95=${(metric.values['p(95)'] || 0).toFixed(2)}ms\n`;
      }
    }
  }
  return summary;
}

