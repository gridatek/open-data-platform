#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Register Trino as a Superset database and prove a query runs through it
# against the governed Iceberg table:  SELECT count(*) FROM iceberg.smoke.events
#
#   SUPERSET_URL  default http://localhost:8088
#   creds         admin / admin
#
# Usage:  ./register-trino.sh
# Requires: curl, jq
# ───────────────────────────────────────────────────────────────
set -euo pipefail

SUPERSET_URL="${SUPERSET_URL:-http://localhost:8088}"
USER="${SUPERSET_USER:-admin}"
PASS="${SUPERSET_PASS:-admin}"
DB_NAME="trino-odp"
SQLA_URI="trino://admin@trino:8080/iceberg"

echo "[superset] waiting for Superset at ${SUPERSET_URL} ..."
until curl -sf "${SUPERSET_URL}/health" >/dev/null; do sleep 5; done

echo "[superset] logging in"
TOKEN=$(curl -sS -X POST "${SUPERSET_URL}/api/v1/security/login" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"${USER}\",\"password\":\"${PASS}\",\"provider\":\"db\",\"refresh\":true}" \
  | jq -r '.access_token')
auth=(-H "Authorization: Bearer ${TOKEN}")

# Find an existing 'trino-odp' database, else create it.
echo "[superset] ensuring database '${DB_NAME}'"
DB_ID=$(curl -sS "${auth[@]}" \
  "${SUPERSET_URL}/api/v1/database/?q=(filters:!((col:database_name,opr:eq,value:${DB_NAME})))" \
  | jq -r '.result[0].id // empty')

if [ -z "${DB_ID}" ]; then
  DB_ID=$(curl -sS -X POST "${SUPERSET_URL}/api/v1/database/" "${auth[@]}" \
    -H 'Content-Type: application/json' \
    -d "{\"database_name\":\"${DB_NAME}\",\"sqlalchemy_uri\":\"${SQLA_URI}\",\"expose_in_sqllab\":true}" \
    | jq -r '.id')
fi
echo "[superset] database id = ${DB_ID}"

echo "[superset] running query via SQL Lab"
RESULT=$(curl -sS -X POST "${SUPERSET_URL}/api/v1/sqllab/execute/" "${auth[@]}" \
  -H 'Content-Type: application/json' \
  -d "{\"database_id\":${DB_ID},\"schema\":\"smoke\",\"sql\":\"SELECT count(*) AS n FROM iceberg.smoke.events\",\"runAsync\":false}")
echo "${RESULT}" | jq '.data // .'

N=$(echo "${RESULT}" | jq -r '.data[0].n')
echo "[superset] count = ${N}"
test "${N}" = "4"
echo "[superset] OK — Superset queried the governed Iceberg table through Trino"
