#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Register a lineage graph in Atlas and verify the edge exists:
#
#     events_source ──[seed_lakehouse]──▶ iceberg.smoke.events
#
#   ATLAS_URL  default http://localhost:21000
#   ATLAS_AUTH default admin:admin
#
# Usage:  ./register-lineage.sh
# Requires: curl, jq
# ───────────────────────────────────────────────────────────────
set -euo pipefail

ATLAS_URL="${ATLAS_URL:-http://localhost:21000}"
ATLAS_AUTH="${ATLAS_AUTH:-admin:admin}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_QN="iceberg.smoke.events@odp"

echo "[atlas] waiting for Atlas REST at ${ATLAS_URL} (can take a few minutes) ..."
until curl -sf -u "${ATLAS_AUTH}" "${ATLAS_URL}/api/atlas/admin/version" >/dev/null; do
  sleep 10
done

echo "[atlas] registering lineage entities"
curl -sS -u "${ATLAS_AUTH}" -H 'Content-Type: application/json' \
  -X POST "${ATLAS_URL}/api/atlas/v2/entity/bulk" \
  --data-binary "@${HERE}/entities/lineage-seed.json" >/dev/null
echo "[atlas] entities posted"

# Resolve the guid of the output table by its unique qualifiedName.
GUID=$(curl -sS -u "${ATLAS_AUTH}" \
  "${ATLAS_URL}/api/atlas/v2/entity/uniqueAttribute/type/DataSet?attr:qualifiedName=${OUT_QN}" \
  | jq -r '.entity.guid')
echo "[atlas] output table guid = ${GUID}"

echo "[atlas] INPUT lineage for ${OUT_QN}:"
curl -sS -u "${ATLAS_AUTH}" \
  "${ATLAS_URL}/api/atlas/v2/lineage/${GUID}?direction=INPUT&depth=3" \
  | tee /tmp/odp-lineage.json \
  | jq '{ relations: .relations, entities: [.guidEntityMap[].attributes.qualifiedName] }'

REL_COUNT=$(jq '.relations | length' /tmp/odp-lineage.json)
echo "[atlas] lineage relations = ${REL_COUNT}"
test "${REL_COUNT}" -ge 1

# Confirm the upstream source actually appears in the graph.
jq -e '[.guidEntityMap[].attributes.qualifiedName] | index("events_source@odp")' \
  /tmp/odp-lineage.json >/dev/null
echo "[atlas] OK — events_source is upstream of ${OUT_QN}"
