.DEFAULT_GOAL := help

# =============================================================================
# AgentMesh — workspace Makefile
#
# `make demo` brings up the full stack from a fresh checkout:
#   shared infra (postgres + redis)  →  application stack via Traefik gateway
#   →  health gate  →  end-to-end smoke probe  →  print operator URLs.
#
# Targets are designed to be **idempotent** and **non-destructive** by default.
# Use `make demo-clean` (with `CONFIRM=yes`) to nuke volumes.
#
# Architect Protocol §4 (sprint demo) + §9 (multi-stage local environments)
# apply: dev convention is `[svc].localhost` (no `-stage`/`-prod` suffix).
# =============================================================================

SHELL          := /bin/bash
.SHELLFLAGS    := -eu -o pipefail -c
MAKEFLAGS      += --warn-undefined-variables --no-print-directory

# --- compose files & gateway hosts -------------------------------------------
COMPOSE_INFRA   := docker-compose.yml
COMPOSE_APP     := docker-compose.gateway.yml
COMPOSE_FILES   := -f $(COMPOSE_INFRA) -f $(COMPOSE_APP)

# --- gateway hostnames (must resolve to 127.0.0.1) ---------------------------
HOST_API        := api.agentmesh.localhost
HOST_UI         := app.agentmesh.localhost
HOST_TRAEFIK    := traefik.agentmesh.localhost

# --- credentials for the smoke probe (matches Flyway V9 admin seed) ----------
ADMIN_USER      := admin
ADMIN_PASS      := admin-change-me

# --- helpers -----------------------------------------------------------------
CYAN    := \033[1;36m
YELLOW  := \033[1;33m
GREEN   := \033[1;32m
RED     := \033[1;31m
RESET   := \033[0m

define banner
	@printf "$(CYAN)\n══════════════════════════════════════════════════════════════════════\n"
	@printf "  %s\n" "$(1)"
	@printf "══════════════════════════════════════════════════════════════════════$(RESET)\n"
endef

# =============================================================================
# Help
# =============================================================================
.PHONY: help
help: ## Show this help (default target)
	@awk 'BEGIN {FS = ":.*?## "; print "AgentMesh — make targets\n"} \
	      /^[a-zA-Z0-9_.-]+:.*?## / {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@printf "\nQuick start:\n  $(GREEN)make demo$(RESET)        # full stack + smoke\n  $(GREEN)make demo-down$(RESET)   # tear down (preserves data)\n\n"

# =============================================================================
# Prereq checks
# =============================================================================
.PHONY: prereqs
prereqs: ## Check Docker / curl / jq / etc. are available
	@command -v docker >/dev/null 2>&1 || { printf "$(RED)docker not found$(RESET)\n"; exit 1; }
	@docker info >/dev/null 2>&1 || { printf "$(RED)docker daemon not reachable — start OrbStack/Docker Desktop$(RESET)\n"; exit 1; }
	@command -v curl   >/dev/null 2>&1 || { printf "$(RED)curl not found$(RESET)\n"; exit 1; }
	@command -v jq     >/dev/null 2>&1 || { printf "$(YELLOW)jq not found — install via brew install jq for richer smoke output$(RESET)\n"; }
	@printf "$(GREEN)✓ prereqs OK$(RESET)\n"

# =============================================================================
# Demo lifecycle
# =============================================================================
.PHONY: demo
demo: prereqs infra-up app-up wait-healthy demo-smoke demo-urls ## Full demo (idempotent): infra + app + smoke + URLs

.PHONY: demo-up
demo-up: prereqs infra-up app-up wait-healthy demo-urls ## Bring up the stack (no smoke)

.PHONY: demo-down
demo-down: ## Stop containers (volumes preserved)
	$(call banner,Tearing down application stack)
	-@docker compose $(COMPOSE_FILES) down --remove-orphans
	@printf "$(GREEN)✓ stack down (volumes preserved — use 'make demo-clean CONFIRM=yes' to wipe)$(RESET)\n"

.PHONY: demo-clean
demo-clean: ## Stop & WIPE volumes (destructive — requires CONFIRM=yes)
ifneq ($(CONFIRM),yes)
	@printf "$(RED)Refusing to wipe — re-run with CONFIRM=yes$(RESET)\n"
	@exit 1
else
	$(call banner,WIPING containers + volumes)
	-@docker compose $(COMPOSE_FILES) down -v --remove-orphans
	@printf "$(GREEN)✓ wiped$(RESET)\n"
endif

.PHONY: demo-status
demo-status: ## Show container status + endpoint probes
	$(call banner,Container status)
	@docker compose $(COMPOSE_FILES) ps --format 'table {{.Name}}\t{{.Status}}\t{{.Ports}}' || true
	@printf "\n"
	$(call banner,Endpoint probes)
	@printf "  health  ➜ "; curl -fsS -o /dev/null -w "%{http_code}\n"  -H "Host: $(HOST_API)" http://localhost/actuator/health         || printf "DOWN\n"
	@printf "  ui      ➜ "; curl -fsS -o /dev/null -w "%{http_code}\n"  -H "Host: $(HOST_UI)"  http://localhost/                          || printf "DOWN\n"
	@printf "  traefik ➜ "; curl -fsS -o /dev/null -w "%{http_code}\n"  -H "Host: $(HOST_TRAEFIK)" http://localhost/api/version          || printf "DOWN\n"

.PHONY: demo-smoke
demo-smoke: ## Run end-to-end smoke probe against the running stack
	@bash scripts/demo-smoke.sh

.PHONY: demo-urls
demo-urls: ## Print operator-friendly URLs
	@printf "\n$(GREEN)AgentMesh demo is up$(RESET)\n"
	@printf "  • UI                 http://$(HOST_UI)/\n"
	@printf "  • API                http://$(HOST_API)/api\n"
	@printf "  • API health         http://$(HOST_API)/actuator/health\n"
	@printf "  • API metrics        http://$(HOST_API)/actuator/prometheus\n"
	@printf "  • Traefik dashboard  http://$(HOST_TRAEFIK)/dashboard/\n"
	@printf "\nLogin (Flyway V9 seed): $(ADMIN_USER) / $(ADMIN_PASS)\n"
	@printf "Tear down:              $(YELLOW)make demo-down$(RESET)\n\n"

.PHONY: demo-logs
demo-logs: ## Tail agentmesh-api logs (last 200 lines)
	@docker compose $(COMPOSE_FILES) logs --tail 200 -f agentmesh-api

# =============================================================================
# Internal building blocks
# =============================================================================
.PHONY: infra-up
infra-up: ## Bring up shared infra (postgres, redis)
	$(call banner,Bringing up shared infrastructure)
	@docker compose -f $(COMPOSE_INFRA) up -d
	@printf "$(GREEN)✓ shared infra up$(RESET)\n"

.PHONY: infra-down
infra-down: ## Stop shared infra
	-@docker compose -f $(COMPOSE_INFRA) down

.PHONY: app-up
app-up: ## Bring up application stack (traefik + agentmesh-api + ui + auto-bads)
	$(call banner,Bringing up application stack via Traefik)
	@docker compose $(COMPOSE_FILES) up -d --build
	@printf "$(GREEN)✓ application stack up$(RESET)\n"

.PHONY: app-down
app-down: ## Stop application stack
	-@docker compose -f $(COMPOSE_APP) down --remove-orphans

.PHONY: wait-healthy
wait-healthy: ## Block until agentmesh-api reports UP (≤ 5 min)
	$(call banner,Waiting for agentmesh-api to become healthy)
	@for i in $$(seq 1 60); do \
	  status=$$(curl -fsS -H "Host: $(HOST_API)" http://localhost/actuator/health 2>/dev/null | grep -oE '"status":"[A-Z]+"' | head -1 | cut -d'"' -f4 || true); \
	  if [ "$$status" = "UP" ]; then \
	    printf "$(GREEN)✓ agentmesh-api is UP (after $${i}×5s)$(RESET)\n"; exit 0; \
	  fi; \
	  printf "  [%2d/60] waiting (status=%s)…\n" $$i "$${status:-pending}"; \
	  sleep 5; \
	done; \
	printf "$(RED)✗ agentmesh-api did not reach UP within 5 minutes — see 'make demo-logs'$(RESET)\n"; exit 1

# =============================================================================
# Helm chart targets (Architect Protocol §9)
# =============================================================================
.PHONY: helm-lint
helm-lint: ## Lint charts/agentmesh against all 3 stage value files
	$(call banner,Helm chart lint — dev / staging / prod)
	@for s in dev staging prod; do \
	  printf "$(CYAN)  ── $$s ─────$(RESET)\n"; \
	  helm lint charts/agentmesh -f charts/agentmesh/values-$$s.yaml; \
	done

.PHONY: helm-template-dev
helm-template-dev: ## Render charts/agentmesh with the dev profile
	@helm template agentmesh charts/agentmesh -n agentmesh -f charts/agentmesh/values-dev.yaml

.PHONY: helm-template-staging
helm-template-staging: ## Render charts/agentmesh with the staging profile
	@helm template agentmesh charts/agentmesh -n agentmesh -f charts/agentmesh/values-staging.yaml

.PHONY: helm-template-prod
helm-template-prod: ## Render charts/agentmesh with the prod profile
	@helm template agentmesh charts/agentmesh -n agentmesh -f charts/agentmesh/values-prod.yaml

# =============================================================================
# UAT
# =============================================================================
.PHONY: uat
uat: ## Run the full UAT script against the running stack
	@bash test-scripts/uat-full-flow-v1.sh

