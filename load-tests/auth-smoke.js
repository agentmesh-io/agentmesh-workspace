/**
 * Auth Smoke — Sprint M13.2 acceptance gate
 *
 * Asserts (verbatim from docs/ROADMAP_M13.md sprint 13.2):
 *
 *   k6 smoke profile passes with Authorization Bearer header; 401 without.
 *
 * Thresholds (any breach fails the run):
 *   http_req_failed{auth:bearer}    rate==0     (every Bearer call must succeed)
 *   http_req_failed{auth:none}      rate==1     (every header-less call must 401)
 *   http_req_failed{auth:tampered}  rate==1     (every bad-signature call must 401)
 *   http_req_duration{auth:bearer}  p(95)<500ms
 *
 * Per Architect Protocol §4 (versioned scenarios): see
 *   docs/tests/M13.2-authnz.md
 *
 * Run locally:
 *   k6 run \
 *     -e BASE_URL=http://api.agentmesh.localhost \
 *     -e USERNAME=admin \
 *     -e PASSWORD=admin-change-me \
 *     load-tests/auth-smoke.js
 *
 * Risk R2 mitigation: setup() mints a fresh token, every iteration uses it
 * directly, and the smoke profile finishes well inside the 15-min access
 * TTL so we never observe a mid-run expiry.
 */

import http from 'k6/http';
import { check, fail } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://api.agentmesh.localhost';
const USERNAME = __ENV.USERNAME || 'admin';
const PASSWORD = __ENV.PASSWORD || 'admin-change-me';

// Default target is `/api/auth/verify` — the forwardAuth probe Spring
// always enforces, independent of the AUTH_ENFORCED rollout flag (Risk
// R6). Once R6 is closed at sprint end and `jwt-auth@file` is attached
// to every router, point this at any protected business endpoint.
const PROTECTED_PATH = __ENV.PROTECTED_PATH || '/api/auth/verify';

export const options = {
  scenarios: {
    auth_smoke: {
      executor: 'shared-iterations',
      vus: 5,
      iterations: 30,           // 6 iterations / VU
      maxDuration: '60s',
    },
  },
  thresholds: {
    // Headline acceptance gate.
    'http_req_failed{auth:bearer}':   ['rate==0'],
    'http_req_failed{auth:none}':     ['rate==1'],
    'http_req_failed{auth:tampered}': ['rate==1'],
    // Latency guard for the authed path (matches the 13.1 first-frame target).
    'http_req_duration{auth:bearer}': ['p(95)<500'],
    // Custom checks must all pass.
    checks: ['rate==1'],
  },
};

export function setup() {
  const res = http.post(
    `${BASE_URL}/api/auth/login`,
    JSON.stringify({ username: USERNAME, password: PASSWORD }),
    { headers: { 'Content-Type': 'application/json' }, tags: { phase: 'setup' } },
  );
  if (res.status !== 200) {
    fail(`login failed: HTTP ${res.status} body=${res.body}`);
  }
  let body;
  try {
    body = res.json();
  } catch (e) {
    fail(`login response not JSON: ${e}`);
  }
  if (!body || !body.accessToken) {
    fail('login response missing accessToken');
  }
  return { accessToken: body.accessToken };
}

/** Mutate the last 3 chars of the token so the signature no longer verifies. */
function tamper(token) {
  if (!token || token.length < 4) return 'x';
  const head = token.slice(0, -3);
  const tail = token.slice(-3);
  // simple deterministic mutation that preserves URL-safe base64 alphabet
  const flipped = tail.replace(/[A-Za-z0-9_-]/g, (c) =>
    c === 'A' ? 'B' : c === 'a' ? 'b' : c === '0' ? '1' : 'A',
  );
  return head + flipped;
}

export default function (data) {
  const url = `${BASE_URL}${PROTECTED_PATH}`;
  const accessToken = data.accessToken;
  const tamperedToken = tamper(accessToken);

  // 1. Bearer — must succeed.
  const bearerRes = http.get(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
    tags: { auth: 'bearer' },
  });
  check(bearerRes, {
    'bearer: status is 2xx': (r) => r.status >= 200 && r.status < 300,
  });

  // 2. No header — must 401.
  const noneRes = http.get(url, { tags: { auth: 'none' } });
  check(noneRes, {
    'none: status is 401': (r) => r.status === 401,
  });

  // 3. Tampered signature — must 401.
  const tamperedRes = http.get(url, {
    headers: { Authorization: `Bearer ${tamperedToken}` },
    tags: { auth: 'tampered' },
  });
  check(tamperedRes, {
    'tampered: status is 401': (r) => r.status === 401,
  });
}

export function handleSummary(data) {
  // Compact stdout summary so CI logs stay short.
  const m = data.metrics;
  const rate = (name, tag) =>
    (m[`http_req_failed{auth:${tag}}`] && m[`http_req_failed{auth:${tag}}`].values.rate) ?? 'n/a';
  const p95 =
    (m['http_req_duration{auth:bearer}'] && m['http_req_duration{auth:bearer}'].values['p(95)']) ?? 'n/a';

  const lines = [
    '── Auth Smoke (M13.2) ──',
    `bearer   fail-rate: ${rate('bearer', 'bearer')}      p95: ${p95} ms`,
    `none     fail-rate: ${rate('none', 'none')}    (must be 1.00)`,
    `tampered fail-rate: ${rate('tampered', 'tampered')} (must be 1.00)`,
    '',
  ];
  return {
    stdout: lines.join('\n'),
    'load-tests/results/auth-smoke.json': JSON.stringify(data, null, 2),
  };
}


