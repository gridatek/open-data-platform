#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Log a run to the MLflow tracking server and read it back — proves the
# tracking server + backend store work. Artifacts are configured to land in
# MinIO (s3://mlflow) via --serve-artifacts.
#
#   MLFLOW_URL  default http://localhost:5000
#
# Usage:  ./log-run.sh
# Requires: curl, jq
# ───────────────────────────────────────────────────────────────
set -euo pipefail

MLFLOW_URL="${MLFLOW_URL:-http://localhost:5000}"
EXP_NAME="odp-smoke"
api="${MLFLOW_URL}/api/2.0/mlflow"
now() { echo "$(date +%s)000"; }

echo "[mlflow] waiting for tracking server at ${MLFLOW_URL} ..."
until curl -sf "${MLFLOW_URL}/health" >/dev/null; do sleep 3; done

echo "[mlflow] ensuring experiment '${EXP_NAME}'"
EXP_ID=$(curl -sS -X POST "${api}/experiments/create" \
  -H 'Content-Type: application/json' \
  -d "{\"name\":\"${EXP_NAME}\"}" | jq -r '.experiment_id // empty')
if [ -z "${EXP_ID}" ]; then
  EXP_ID=$(curl -sS "${api}/experiments/get-by-name?experiment_name=${EXP_NAME}" \
    | jq -r '.experiment.experiment_id')
fi
echo "[mlflow] experiment_id=${EXP_ID}"

echo "[mlflow] creating run"
RUN_ID=$(curl -sS -X POST "${api}/runs/create" \
  -H 'Content-Type: application/json' \
  -d "{\"experiment_id\":\"${EXP_ID}\",\"start_time\":$(now)}" \
  | jq -r '.run.info.run_id')
echo "[mlflow] run_id=${RUN_ID}"

curl -sS -X POST "${api}/runs/log-parameter" -H 'Content-Type: application/json' \
  -d "{\"run_id\":\"${RUN_ID}\",\"key\":\"source\",\"value\":\"iceberg.smoke.events\"}" >/dev/null
curl -sS -X POST "${api}/runs/log-metric" -H 'Content-Type: application/json' \
  -d "{\"run_id\":\"${RUN_ID}\",\"key\":\"rows\",\"value\":4,\"timestamp\":$(now),\"step\":0}" >/dev/null
curl -sS -X POST "${api}/runs/update" -H 'Content-Type: application/json' \
  -d "{\"run_id\":\"${RUN_ID}\",\"status\":\"FINISHED\",\"end_time\":$(now)}" >/dev/null

echo "[mlflow] reading the run back"
GOT=$(curl -sS "${api}/runs/get?run_id=${RUN_ID}" \
  | jq -r '.run.data.metrics[] | select(.key=="rows") | .value')
echo "[mlflow] logged rows metric = ${GOT}"
test "${GOT%%.*}" = "4"

# ── Artifact round-trip through the artifact store (MinIO via --serve-artifacts).
# Proves the S3 path, not just the metadata DB: the server writes the file to
# s3://mlflow/... with its boto3 creds, then serves it back.
echo "[mlflow] uploading an artifact (lands in MinIO via the proxy)"
ART_URI=$(curl -sS "${api}/runs/get?run_id=${RUN_ID}" | jq -r '.run.info.artifact_uri')
REL="${ART_URI#mlflow-artifacts:/}"          # strip the proxy scheme → exp/run/artifacts
MARKER="odp-artifact-$(date +%s)"
proxy="${MLFLOW_URL}/api/2.0/mlflow-artifacts/artifacts"
curl -sS -X PUT "${proxy}/${REL}/note.txt" --data-binary "${MARKER}" >/dev/null

echo "[mlflow] confirming it's registered + reading it back"
curl -sS "${api}/artifacts/list?run_id=${RUN_ID}" | jq -e '.files[] | select(.path=="note.txt")' >/dev/null
BACK=$(curl -sS "${proxy}/${REL}/note.txt")
echo "[mlflow] artifact content = ${BACK}"
test "${BACK}" = "${MARKER}"

echo "[mlflow] OK — run + metric in the backend store, artifact round-tripped through MinIO"
