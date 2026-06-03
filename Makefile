# Open Data Platform — one-command operation of the docker-compose laptop subset.
# Each overlay layers onto the Phase 0 lakehouse. Compose globs them together.

COMPOSE := docker compose --project-directory quickstart \
  -f quickstart/docker-compose.yml \
  -f quickstart/docker-compose.governance.yml \
  -f quickstart/docker-compose.services.yml \
  -f quickstart/docker-compose.console.yml

CORE := docker compose --project-directory quickstart -f quickstart/docker-compose.yml

.DEFAULT_GOAL := help
.PHONY: help env core all governance services console seed smoke down ps logs

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

env: ## Create quickstart/.env from the example if missing
	@test -f quickstart/.env || cp quickstart/.env.example quickstart/.env

core: env ## Phase 0 — just the lakehouse (MinIO + catalog + Trino + Spark)
	$(CORE) up -d

all: env ## Bring up the WHOLE platform (heavy: Ranger build, Atlas, all services)
	$(COMPOSE) up -d --build

governance: env ## Lakehouse + Ranger/Atlas (the SDX clone)
	docker compose --project-directory quickstart \
	  -f quickstart/docker-compose.yml \
	  -f quickstart/docker-compose.governance.yml up -d --build

services: env ## Lakehouse + Superset/Airflow/MLflow/Kafka/NiFi
	docker compose --project-directory quickstart \
	  -f quickstart/docker-compose.yml \
	  -f quickstart/docker-compose.services.yml up -d

console: env ## Lakehouse + governance + the console control plane
	docker compose --project-directory quickstart \
	  -f quickstart/docker-compose.yml \
	  -f quickstart/docker-compose.governance.yml \
	  -f quickstart/docker-compose.console.yml up -d --build

seed: ## Run the Spark seed job into iceberg.smoke.events
	$(COMPOSE) exec spark spark-submit /home/iceberg/jobs/seed_lakehouse.py

down: ## Stop everything and wipe volumes
	$(COMPOSE) down -v

ps: ## Show running services
	$(COMPOSE) ps

logs: ## Tail logs
	$(COMPOSE) logs -f
