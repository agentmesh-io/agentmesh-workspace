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

const headers = {
  'Content-Type': 'application/json',
};

// ─── Scenarios ──────────────────────────────────────────────────
export default function () {
  group('AgentMesh Health', () => {
    const res = http.get(`${AGENTMESH_URL}/actuator/health`);
    check(res, {
      'AgentMesh health status 200': (r) => r.status === 200,
      'AgentMesh health body contains UP': (r) => r.body && r.body.includes('UP'),
    }) || errorRate.add(1);
  });

  group('AgentMesh Project Initialize', () => {
    const payload = JSON.stringify({
      name: `LoadTest-Project-${__VU}-${__ITER}`,
      description: `Load test project from VU ${__VU} iteration ${__ITER}`,
    });

    const res = http.post(`${AGENTMESH_URL}/api/projects/initialize`, payload, { headers });
    projectInitDuration.add(res.timings.duration);

    check(res, {
      'Project init status 200 or 201': (r) => r.status === 200 || r.status === 201,
      'Project init response has body': (r) => r.body && r.body.length > 0,
    }) || errorRate.add(1);
  });

  group('AgentMesh Project Status', () => {
    const res = http.get(`${AGENTMESH_URL}/api/projects/status`);
    check(res, {
      'Project status 200': (r) => r.status === 200,
    }) || errorRate.add(1);
  });

  group('AgentMesh Metrics', () => {
    const res = http.get(`${AGENTMESH_URL}/actuator/prometheus`);
    check(res, {
      'Prometheus metrics 200': (r) => r.status === 200,
      'Metrics contain JVM info': (r) => r.body && r.body.includes('jvm_'),
    }) || errorRate.add(1);
  });

  group('Auto-BADS Health', () => {
    const res = http.get(`${AUTOBADS_URL}/actuator/health`);
    check(res, {
      'Auto-BADS health status 200': (r) => r.status === 200,
    }) || errorRate.add(1);
  });

  sleep(0.5 + Math.random() * 0.5); // 0.5–1s think time
}

// ─── Summary ──────────────────────────────────────────────────
export function handleSummary(data) {
  const now = new Date().toISOString().replace(/[:.]/g, '-');
  return {
    [`results/summary-${__ENV.PROFILE || 'smoke'}-${now}.json`]: JSON.stringify(data, null, 2),
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

