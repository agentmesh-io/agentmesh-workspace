# 🌐 API Gateway & Service Mesh Guide

**Last Updated:** April 18, 2026

## Service Routing (Traefik)

| Service | Direct Port | Gateway Route | Protocol Port Range |
|---------|------------|---------------|-------------------|
| Traefik Dashboard | - | http://traefik.localhost | - |
| AgentMesh API | 8080 | http://api.localhost | 8081-8100 (Java) |
| AgentMesh UI | 3000 | http://app.localhost | 5173-5200 (Node/FE) |
| Auto-BADS | 8083 | http://bads.localhost | 8081-8100 (Java) |
| LMStudio | 1234 | http://llm.localhost | 1234 (LLM) |
| Prometheus | 9090 | http://metrics.localhost | - |
| Grafana | 3000 | http://grafana.localhost | 3000-3099 (Go) |

## Quick Start

```bash
# Start gateway + all services
docker compose -f docker-compose.gateway.yml up -d

# Access
open http://app.localhost       # UI
open http://api.localhost       # Backend API
open http://traefik.localhost   # Gateway dashboard
```

## Authentication

### Development Mode (default)
- No API key required
- All endpoints open

### Production Mode
```bash
export API_KEY_AUTH_ENABLED=true
export AGENTMESH_API_KEY=your-secure-key-here
```

Then include in requests:
```bash
curl -H "X-API-Key: your-secure-key-here" http://api.localhost/api/agents
# or
curl -H "Authorization: Bearer your-secure-key-here" http://api.localhost/api/agents
```

## Rate Limiting

| Service | Requests/sec | Burst |
|---------|-------------|-------|
| AgentMesh API | 100 | 50 |
| Auto-BADS | 50 | 20 |

## Middlewares

- **Rate Limiting** — per-service configurable
- **Security Headers** — XSS, HSTS, nosniff
- **CORS** — configured for UI origins
- **Circuit Breaker** — trips at >30% 5xx rate
- **Retry** — 3 attempts with 100ms initial interval
- **Compression** — gzip for all non-streaming responses

## Architecture

```
                    ┌─────────────┐
                    │   Traefik   │ :80 / :443
                    │   Gateway   │
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
  ┌───────┴───────┐ ┌─────┴──────┐ ┌───────┴───────┐
  │  AgentMesh    │ │ AgentMesh  │ │   Auto-BADS   │
  │  API :8080    │ │  UI :3000  │ │    :8083      │
  │ api.localhost │ │app.localhost│ │bads.localhost │
  └───────┬───────┘ └────────────┘ └───────┬───────┘
          │                                │
          └──────────┐    ┌────────────────┘
                     │    │
              ┌──────┴────┴──────┐
              │   LMStudio       │
              │  :1234/v1        │
              │ (host network)   │
              └──────────────────┘
```

