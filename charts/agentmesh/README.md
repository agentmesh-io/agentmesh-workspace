# AgentMesh Helm chart

Stage-aware Helm chart for the AgentMesh modular monolith. Aligned with
**Architect Protocol §9** (multi-stage local environments) host-routing
and naming conventions, and the M13.3 R6 close (Spring fails closed by
default — see [`docs/ACCEPTANCE_M13.3.md`](../../docs/ACCEPTANCE_M13.3.md)).

## Layout

```
charts/agentmesh/
├── Chart.yaml
├── values.yaml                # shared defaults (no host — set per stage)
├── values-dev.yaml            # 1× replica, AUTH_ENFORCED=false, DEBUG logs
├── values-staging.yaml        # 2× HPA, PDB, NetworkPolicy, AUTH_ENFORCED=true
├── values-prod.yaml           # 3× HPA 3–10, TLS, externalised secret
├── .helmignore
└── templates/
    ├── _helpers.tpl
    ├── serviceaccount.yaml
    ├── configmap.yaml
    ├── secret.yaml            # only when secret.create=true
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── hpa.yaml
    ├── pdb.yaml
    ├── networkpolicy.yaml
    └── NOTES.txt
```

## Stage profiles

| Stage   | Host                              | Replicas | HPA   | PDB | NetworkPolicy | AUTH_ENFORCED | Secret source            |
|---------|-----------------------------------|----------|-------|-----|---------------|---------------|--------------------------|
| dev     | `api.agentmesh.localhost`         | 1        | off   | off | off           | `false`       | in-chart                 |
| staging | `api-stage.agentmesh.localhost`   | 2        | 2–4   | 1   | on            | `true`        | in-chart                 |
| prod    | `api.agentmesh.io` (override)     | 3        | 3–10  | 2   | on            | `true`        | external (`existingSecret`) |

The host pattern matches Architect Protocol §9:

* dev:   `[svc].localhost`
* stage: `[svc]-stage.localhost`
* prod:  `[svc]-prod.localhost` *(or a real public host via `--set ingress.host=…`)*

## Quickstart

```sh
# Lint everything
helm lint charts/agentmesh -f charts/agentmesh/values-dev.yaml
helm lint charts/agentmesh -f charts/agentmesh/values-staging.yaml
helm lint charts/agentmesh -f charts/agentmesh/values-prod.yaml

# Render only (no cluster needed)
helm template agentmesh charts/agentmesh -n agentmesh \
  -f charts/agentmesh/values-dev.yaml | less

# Install (dev)
helm upgrade --install agentmesh charts/agentmesh \
  -n agentmesh --create-namespace \
  -f charts/agentmesh/values-dev.yaml

# Install (prod) — assumes `agentmesh-secrets` already exists in-cluster
helm upgrade --install agentmesh charts/agentmesh \
  -n agentmesh --create-namespace \
  -f charts/agentmesh/values-prod.yaml \
  --set ingress.host=api.your-domain.example
```

## Stage-specific overrides

You can stack profiles or override individual keys at install time:

```sh
# Staging with a custom image tag
helm upgrade --install agentmesh charts/agentmesh \
  -n agentmesh-stage --create-namespace \
  -f charts/agentmesh/values-staging.yaml \
  --set image.tag=v1.1.0-rc1

# Prod with TLS via cert-manager
helm upgrade --install agentmesh charts/agentmesh \
  -n agentmesh-prod --create-namespace \
  -f charts/agentmesh/values-prod.yaml \
  --set ingress.host=api.example.com \
  --set ingress.tls.secretName=agentmesh-tls
```

## Required external resources

The chart deliberately does **not** package shared infrastructure. The
following must already be reachable from the target namespace before
install (or wait-init containers will block startup):

| Service | Host (default) | Port |
|---------|----------------|------|
| Postgres | `postgres`    | 5432 |
| Redis    | `redis`       | 6379 |
| Kafka    | `kafka`       | 9092 |

For local Kubernetes you can mirror the workspace's
`docker-compose.gateway.yml` services, or pull in dependent charts (Bitnami
`postgresql`/`redis`/`kafka`) in a parent umbrella chart.

## Probes

The chart wires Spring Boot Actuator probes. The defaults match the
**M13.3 c1 public-bypass router** path set, so the same probes work
identically through Traefik or directly against the pod:

* startup:   `/actuator/health`
* liveness:  `/actuator/health/liveness`
* readiness: `/actuator/health/readiness`

## Rollback

```sh
helm -n agentmesh history agentmesh
helm -n agentmesh rollback agentmesh <REVISION>
```

The chart includes `checksum/config` and `checksum/secret` pod
annotations so config/secret changes always trigger rolling restarts.

## Notes & next steps

* M13.3 commit 4 will harden the K8s manifests further (PSA labels,
  tighter NetworkPolicy egress, HPA tuned to load-test numbers).
* M13.3 commit 5 will introduce the `make demo` target which calls
  this chart for the local lane.

