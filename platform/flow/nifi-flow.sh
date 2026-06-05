#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# NiFi automated-flow proof — build a minimal flow through the REST API and prove
# it runs: create a GenerateFlowFile processor (auto-terminating `success`), start
# it, and assert it produced flowfiles. This is the first automated flow (NiFi
# previously ran but did nothing); a Kafka -> Iceberg/Trino sink is the larger
# follow-up noted in platform/flow/README.md.
#
#   NIFI_URL  default http://localhost:8095   (compose maps 8095 -> nifi 8080)
#
# Usage:  ./nifi-flow.sh        (requires curl, jq)
# ───────────────────────────────────────────────────────────────
set -euo pipefail

NIFI="${NIFI_URL:-http://localhost:8095}/nifi-api"

echo "[nifi] waiting for the REST API at ${NIFI} ..."
until curl -sf "${NIFI}/flow/process-groups/root" >/dev/null 2>&1; do sleep 3; done

ROOT=$(curl -sf "${NIFI}/flow/process-groups/root" | jq -r '.processGroupFlow.id')
echo "[nifi] root process group = ${ROOT}"

# Current revision version of a processor (needed on every mutating call).
rev() { curl -sf "${NIFI}/processors/$1" | jq -r '.revision.version'; }

echo "[nifi] creating a GenerateFlowFile processor (auto-terminate success)"
GEN_ID=$(curl -sS -X POST "${NIFI}/process-groups/${ROOT}/processors" \
  -H 'Content-Type: application/json' -d '{
    "revision": {"version": 0},
    "component": {
      "type": "org.apache.nifi.processors.standard.GenerateFlowFile",
      "name": "odp-generate-events",
      "position": {"x": 0, "y": 0},
      "config": {
        "schedulingPeriod": "1 sec",
        "autoTerminatedRelationships": ["success"]
      }
    }
  }' | jq -r '.id')
echo "[nifi] processor id = ${GEN_ID}"
trap 'curl -sS -X PUT "${NIFI}/processors/${GEN_ID}/run-status" -H "Content-Type: application/json" -d "{\"revision\":{\"version\":$(rev "${GEN_ID}")},\"state\":\"STOPPED\"}" >/dev/null 2>&1 || true' EXIT

echo "[nifi] starting the flow"
curl -sS -X PUT "${NIFI}/processors/${GEN_ID}/run-status" -H 'Content-Type: application/json' \
  -d "{\"revision\":{\"version\":$(rev "${GEN_ID}")},\"state\":\"RUNNING\"}" >/dev/null

echo "[nifi] waiting for the flow to produce flowfiles ..."
for i in $(seq 1 30); do
  OUT=$(curl -sf "${NIFI}/processors/${GEN_ID}" | jq -r '.status.aggregateSnapshot.flowFilesOut // "0"')
  echo "  flowFilesOut=${OUT} (${i})"
  if [ "${OUT%% *}" -ge 1 ] 2>/dev/null; then
    echo "[nifi] OK — NiFi built and ran an automated flow via the REST API (flowFilesOut=${OUT})."
    exit 0
  fi
  sleep 3
done

echo "[nifi] FAIL — the flow never produced a flowfile." >&2
exit 1
