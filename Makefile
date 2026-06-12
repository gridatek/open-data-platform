# Open Data Platform — one-command operation of the docker-compose laptop subset.
# Each overlay layers onto the Phase 0 lakehouse. Compose globs them together.

COMPOSE := docker compose --project-directory quickstart \
  -f quickstart/docker-compose.yml \
  -f quickstart/docker-compose.governance.yml \
  -f quickstart/docker-compose.services.yml \
  -f quickstart/docker-compose.console.yml \
  -f quickstart/docker-compose.opdb.yml \
  -f quickstart/docker-compose.jupyterhub.yml \
  -f quickstart/docker-compose.knox.yml \
  -f quickstart/docker-compose.hue.yml

CORE := docker compose --project-directory quickstart -f quickstart/docker-compose.yml

.DEFAULT_GOAL := help
.PHONY: help env core all governance services console opdb jupyterhub knox hue hive seed down ps logs

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

opdb: env ## Operational DB — HBase + Phoenix (standalone)
	docker compose --project-directory quickstart \
	  -f quickstart/docker-compose.opdb.yml up -d

jupyterhub: env ## JupyterHub — multi-user notebooks (standalone)
	docker compose --project-directory quickstart \
	  -f quickstart/docker-compose.jupyterhub.yml up -d --build

knox: env ## Lakehouse + Knox gateway (the perimeter; add other overlays as needed)
	docker compose --project-directory quickstart \
	  -f quickstart/docker-compose.yml \
	  -f quickstart/docker-compose.knox.yml up -d --build

hue: env ## Lakehouse + Hue (the web SQL editor over Trino)
	docker compose --project-directory quickstart \
	  -f quickstart/docker-compose.yml \
	  -f quickstart/docker-compose.hue.yml up -d

hive: env ## LEGACY lab — Trino + Hive Metastore over MinIO (the Hive->Iceberg lesson; lean)
	docker compose --project-directory quickstart \
	  -f quickstart/docker-compose.yml \
	  -f quickstart/docker-compose.hive.yml up -d minio minio-init trino hive-metastore

seed: ## Run the Spark seed job into iceberg.smoke.events
	$(COMPOSE) exec spark spark-submit /home/iceberg/jobs/seed_lakehouse.py

down: ## Stop everything and wipe volumes
	$(COMPOSE) down -v

ps: ## Show running services
	$(COMPOSE) ps

logs: ## Tail logs
	$(COMPOSE) logs -f
