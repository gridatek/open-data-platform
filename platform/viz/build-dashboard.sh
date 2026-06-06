#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Build a Superset dataset → chart → dashboard over the analyst's
# iceberg.analytics.orders table, entirely through the Superset REST API —
# the runnable, CI-proven backing for labs/02-data-analyst/lab-03-superset-dashboard.md.
#
# Prereqs (idempotent, safe to re-run):
#   - Superset up and the 'trino-odp' database registered (register-trino.sh)
#   - the orders table built (platform/warehouse/run-analytics-sql.sh)
#
#   SUPERSET_URL  default http://localhost:8088   ·  creds admin / admin
#
# Usage:  ./build-dashboard.sh
# Requires: curl, jq
# ───────────────────────────────────────────────────────────────
set -euo pipefail

SUPERSET_URL="${SUPERSET_URL:-http://localhost:8088}"
USER="${SUPERSET_USER:-admin}"
PASS="${SUPERSET_PASS:-admin}"
DB_NAME="trino-odp"
SCHEMA="analytics"
TABLE="orders"
CHART_NAME="Revenue by region"
DASH_NAME="Sales overview"

JAR="$(mktemp)"; trap 'rm -f "${JAR}"' EXIT

echo "[superset] waiting for Superset at ${SUPERSET_URL} ..."
until curl -sf "${SUPERSET_URL}/health" >/dev/null; do sleep 5; done

echo "[superset] logging in"
TOKEN=$(curl -sS -c "${JAR}" -X POST "${SUPERSET_URL}/api/v1/security/login" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"${USER}\",\"password\":\"${PASS}\",\"provider\":\"db\",\"refresh\":true}" \
  | jq -r '.access_token')
auth=(-H "Authorization: Bearer ${TOKEN}")
CSRF=$(curl -sS -b "${JAR}" -c "${JAR}" "${auth[@]}" \
  "${SUPERSET_URL}/api/v1/security/csrf_token/" | jq -r '.result')
post=(-b "${JAR}" -H "X-CSRFToken: ${CSRF}" -H "Referer: ${SUPERSET_URL}/" \
      -H 'Content-Type: application/json')

# 1) the trino-odp database must already be registered (register-trino.sh)
DB_ID=$(curl -sS "${auth[@]}" \
  "${SUPERSET_URL}/api/v1/database/?q=(filters:!((col:database_name,opr:eq,value:${DB_NAME})))" \
  | jq -r '.result[0].id // empty')
[ -n "${DB_ID}" ] || { echo "ERROR: database '${DB_NAME}' not found — run register-trino.sh first"; exit 1; }
echo "[superset] database id = ${DB_ID}"

# 2) dataset over analytics.orders (find existing, else create)
DS_ID=$(curl -sS "${auth[@]}" \
  "${SUPERSET_URL}/api/v1/dataset/?q=(filters:!((col:table_name,opr:eq,value:${TABLE})))" \
  | jq -r ".result[] | select(.schema==\"${SCHEMA}\") | .id" | head -1)
if [ -z "${DS_ID}" ]; then
  DS_ID=$(curl -sS -X POST "${SUPERSET_URL}/api/v1/dataset/" "${auth[@]}" "${post[@]}" \
    -d "{\"database\":${DB_ID},\"schema\":\"${SCHEMA}\",\"table_name\":\"${TABLE}\"}" \
    | jq -r '.id')
fi
echo "[superset] dataset id = ${DS_ID}"

# 3) a bar chart: SUM(amount) by region (find existing by name client-side, else create)
CHART_ID=$(curl -sS "${auth[@]}" "${SUPERSET_URL}/api/v1/chart/?q=(page_size:100)" \
  | jq -r ".result[] | select(.slice_name==\"${CHART_NAME}\") | .id" | head -1)
if [ -z "${CHART_ID}" ]; then
  PARAMS=$(jq -nc --argjson ds "${DS_ID}" '{
    datasource: ($ds|tostring)+"__table", viz_type: "echarts_timeseries_bar",
    x_axis: "region", groupby: ["region"],
    metrics: [{label:"SUM(amount)", expressionType:"SIMPLE",
               column:{column_name:"amount"}, aggregate:"SUM"}],
    row_limit: 100 }')
  CHART_ID=$(curl -sS -X POST "${SUPERSET_URL}/api/v1/chart/" "${auth[@]}" "${post[@]}" \
    -d "$(jq -nc --arg n "${CHART_NAME}" --argjson ds "${DS_ID}" --arg p "${PARAMS}" '{
          slice_name:$n, viz_type:"echarts_timeseries_bar",
          datasource_id:$ds, datasource_type:"table", params:$p }')" \
    | jq -r '.id')
fi
echo "[superset] chart id = ${CHART_ID}"

# 4) the dashboard (find existing by title client-side, else create)
DASH_ID=$(curl -sS "${auth[@]}" "${SUPERSET_URL}/api/v1/dashboard/?q=(page_size:100)" \
  | jq -r ".result[] | select(.dashboard_title==\"${DASH_NAME}\") | .id" | head -1)
if [ -z "${DASH_ID}" ]; then
  DASH_ID=$(curl -sS -X POST "${SUPERSET_URL}/api/v1/dashboard/" "${auth[@]}" "${post[@]}" \
    -d "$(jq -nc --arg t "${DASH_NAME}" --argjson c "${CHART_ID}" \
          '{dashboard_title:$t, published:true, position_json:("{\"DASHBOARD_VERSION_KEY\":\"v2\"}")}')" \
    | jq -r '.id')
fi
echo "[superset] dashboard id = ${DASH_ID}"

# 5) attach the chart to the dashboard (m2m on the chart side — no brittle layout JSON)
curl -sS -X PUT "${SUPERSET_URL}/api/v1/chart/${CHART_ID}" "${auth[@]}" "${post[@]}" \
  -d "$(jq -nc --argjson d "${DASH_ID}" '{dashboards:[$d]}')" >/dev/null
echo "[superset] attached chart ${CHART_ID} to dashboard ${DASH_ID}"

# 6) assert everything is really there, queried back through the API
echo "[superset] verifying ..."
test -n "${DS_ID}"
test "$(curl -sS "${auth[@]}" "${SUPERSET_URL}/api/v1/chart/${CHART_ID}" | jq -r '.result.slice_name')" = "${CHART_NAME}"
test "$(curl -sS "${auth[@]}" "${SUPERSET_URL}/api/v1/dashboard/${DASH_ID}" | jq -r '.result.dashboard_title')" = "${DASH_NAME}"
# the chart now belongs to the dashboard
test "$(curl -sS "${auth[@]}" "${SUPERSET_URL}/api/v1/chart/${CHART_ID}" \
        | jq -r "[.result.dashboards[].id] | index(${DASH_ID}) // empty")" != ""
echo "[superset] OK — '${DASH_NAME}' dashboard carries chart '${CHART_NAME}' over governed Iceberg via Trino"
