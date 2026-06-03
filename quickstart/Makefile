# Phase 0 lakehouse — convenience targets.
#   make up    → copy .env (if missing) and start the stack
#   make seed  → run the Spark job that writes the demo Iceberg table
#   make smoke → read the table back from Trino
#   make down  → stop everything and wipe volumes

COMPOSE := docker compose

.PHONY: up down seed smoke logs ps

up:
	@test -f .env || cp .env.example .env
	$(COMPOSE) up -d

down:
	$(COMPOSE) down -v

seed:
	$(COMPOSE) exec spark spark-submit /home/iceberg/jobs/seed_lakehouse.py

smoke:
	$(COMPOSE) exec -T trino trino --execute "SELECT * FROM iceberg.smoke.events ORDER BY id;"

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps
