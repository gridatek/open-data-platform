#!/usr/bin/env bash
# One-command bootstrap of the Open Data Platform (docker-compose laptop subset).
#
#   ./bootstrap.sh            # bring up the whole platform
#   ./bootstrap.sh core       # just the Phase 0 lakehouse
#   ./bootstrap.sh down       # tear everything down
#
# Requires: docker (with the compose plugin).
set -euo pipefail
cd "$(dirname "$0")"

[ -f quickstart/.env ] || cp quickstart/.env.example quickstart/.env

COMPOSE=(docker compose --project-directory quickstart
  -f quickstart/docker-compose.yml
  -f quickstart/docker-compose.governance.yml
  -f quickstart/docker-compose.services.yml
  -f quickstart/docker-compose.console.yml)

case "${1:-all}" in
  core)
    docker compose --project-directory quickstart -f quickstart/docker-compose.yml up -d
    ;;
  down)
    "${COMPOSE[@]}" down -v
    ;;
  all|"")
    echo "Bringing up the whole platform (this is heavy — Ranger build, Atlas, all services)."
    "${COMPOSE[@]}" up -d --build
    ;;
  *)
    echo "usage: $0 [all|core|down]" >&2; exit 1
    ;;
esac

echo
echo "Console : http://localhost:8090/api/services"
echo "Superset: http://localhost:8088   Airflow: http://localhost:8082   MLflow: http://localhost:5000"
echo "Ranger  : http://localhost:6080   Atlas:   http://localhost:21000  NiFi:   http://localhost:8095/nifi"
