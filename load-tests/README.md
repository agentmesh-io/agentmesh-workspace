# 📊 Load Testing — AgentMesh Platform

## Prerequisites

Install [k6](https://k6.io/docs/get-started/installation/):

```bash
brew install k6
```

## Running Tests

### Smoke Test (5 users, 30s)
```bash
k6 run --env PROFILE=smoke load-test.js
```

### Load Test (100 users, 60s)
```bash
k6 run --env PROFILE=load load-test.js
```

### Stress Test (500 users, 120s)
```bash
k6 run --env PROFILE=stress load-test.js
```

### Custom URLs
```bash
k6 run --env PROFILE=load \
       --env AGENTMESH_URL=http://api.localhost \
       --env AUTOBADS_URL=http://bads.localhost \
       load-test.js
```

## Acceptance Thresholds

| Profile | p95 Latency | Error Rate | Target |
|---------|-------------|------------|--------|
| **smoke** | < 1000ms | < 5% | Basic sanity |
| **load** | < 500ms | < 1% | Production target |
| **stress** | < 2000ms | < 10% | Breaking point discovery |

## Endpoints Tested

| Endpoint | Method | Service |
|----------|--------|---------|
| `/actuator/health` | GET | AgentMesh |
| `/api/projects/initialize` | POST | AgentMesh |
| `/api/projects/status` | GET | AgentMesh |
| `/actuator/prometheus` | GET | AgentMesh |
| `/actuator/health` | GET | Auto-BADS |

## Results

Results are saved to `results/summary-{profile}-{timestamp}.json`.

