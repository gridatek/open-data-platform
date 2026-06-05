#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Automatic lineage proof: run a Spark transform with the OpenLineage listener so
# lineage is *captured automatically* from the job, bridge the emitted events into
# Atlas, and verify the edge  iceberg.smoke.events -> iceberg.smoke.events_curated
# is queryable in Atlas — no hand-authored entities.
#
# Run from quickstart/ with atlas + spark + the lakehouse (trino) up.
#   ATLAS_URL  default http://localhost:21000
#   ATLAS_AUTH default admin:admin
# ───────────────────────────────────────────────────────────────
set -euo pipefail

ATLAS_URL="${ATLAS_URL:-http://localhost:21000}"
ATLAS_AUTH="${ATLAS_AUTH:-admin:admin}"
OL_PKG="io.openlineage:openlineage-spark_2.12:1.24.2"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DC="docker compose -f docker-compose.yml -f docker-compose.governance.yml"

echo "[auto-lineage] waiting for Atlas REST (can take a few minutes) ..."
until curl -sf -u "${ATLAS_AUTH}" "${ATLAS_URL}/api/atlas/admin/version" >/dev/null; do sleep 10; done

echo "[auto-lineage] seeding demo.smoke.events ..."
${DC} exec -T spark spark-submit /home/iceberg/jobs/seed_lakehouse.py >/dev/null

echo "[auto-lineage] running the transform with the OpenLineage Spark listener ..."
${DC} exec -T spark bash -c "
  mkdir -p /tmp/ol
  spark-submit --packages ${OL_PKG} \
    --conf spark.extraListeners=io.openlineage.spark.agent.OpenLineageSparkListener \
    --conf spark.openlineage.transport.type=file \
    --conf spark.openlineage.transport.location=/tmp/ol/lineage.jsonl \
    --conf spark.openlineage.namespace=odp \
    /home/iceberg/jobs/transform_events.py
"

echo "[auto-lineage] bridging the captured OpenLineage events into Atlas ..."
${DC} exec -T spark cat /tmp/ol/lineage.jsonl > /tmp/ol-lineage.jsonl
ATLAS_URL="${ATLAS_URL}" ATLAS_AUTH="${ATLAS_AUTH}" \
  python3 "${HERE}/lineage-from-openlineage.py" /tmp/ol-lineage.jsonl

echo "[auto-lineage] verifying the edge in Atlas ..."
OUT_QN="iceberg.smoke.events_curated@odp"
GUID=$(curl -sS -u "${ATLAS_AUTH}" \
  "${ATLAS_URL}/api/atlas/v2/entity/uniqueAttribute/type/DataSet?attr:qualifiedName=${OUT_QN}" \
  | jq -r '.entity.guid')
echo "[auto-lineage] ${OUT_QN} guid = ${GUID}"
curl -sS -u "${ATLAS_AUTH}" \
  "${ATLAS_URL}/api/atlas/v2/lineage/${GUID}?direction=INPUT&depth=3" \
  | tee /tmp/auto-lineage.json \
  | jq '{ relations: (.relations | length), entities: [.guidEntityMap[].attributes.qualifiedName] }'
jq -e '[.guidEntityMap[].attributes.qualifiedName] | index("iceberg.smoke.events@odp")' \
  /tmp/auto-lineage.json >/dev/null

echo "[auto-lineage] OK — Spark lineage captured via OpenLineage is queryable in Atlas."
