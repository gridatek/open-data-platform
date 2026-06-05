#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# MLflow Model Registry proof — register a model + version through the REST API
# and read it back. The registry needs a database backend store (we use Postgres,
# not a file store), so this also exercises that.
#
#   MLFLOW_URL   default http://localhost:5000
#   MODEL_NAME   default odp-demo-model
#
# Usage:  ./register-model.sh        (requires curl, jq)
# ───────────────────────────────────────────────────────────────
set -euo pipefail

MLFLOW_URL="${MLFLOW_URL:-http://localhost:5000}"
MODEL="${MODEL_NAME:-odp-demo-model}"
EXP="odp-models"
api="${MLFLOW_URL}/api/2.0/mlflow"
now() { echo "$(date +%s)000"; }

echo "[mlflow] waiting for the tracking server at ${MLFLOW_URL} ..."
until curl -sf "${MLFLOW_URL}/health" >/dev/null; do sleep 3; done

echo "[mlflow] creating a run to register a model version against"
EXP_ID=$(curl -sS -X POST "${api}/experiments/create" \
  -H 'Content-Type: application/json' -d "{\"name\":\"${EXP}\"}" \
  | jq -r '.experiment_id // empty')
if [ -z "${EXP_ID}" ]; then
  EXP_ID=$(curl -sS "${api}/experiments/get-by-name?experiment_name=${EXP}" \
    | jq -r '.experiment.experiment_id')
fi
RUN=$(curl -sS -X POST "${api}/runs/create" -H 'Content-Type: application/json' \
  -d "{\"experiment_id\":\"${EXP_ID}\",\"start_time\":$(now)}")
RUN_ID=$(echo "${RUN}" | jq -r '.run.info.run_id')
SOURCE=$(echo "${RUN}" | jq -r '.run.info.artifact_uri')/model
echo "[mlflow] run_id=${RUN_ID}"

echo "[mlflow] registering model '${MODEL}'"
# Idempotent: ignore "already exists".
curl -sS -X POST "${api}/registered-models/create" -H 'Content-Type: application/json' \
  -d "{\"name\":\"${MODEL}\"}" >/dev/null 2>&1 || true
VERSION=$(curl -sS -X POST "${api}/model-versions/create" -H 'Content-Type: application/json' \
  -d "{\"name\":\"${MODEL}\",\"source\":\"${SOURCE}\",\"run_id\":\"${RUN_ID}\"}" \
  | jq -r '.model_version.version')
echo "[mlflow] created ${MODEL} version ${VERSION}"

echo "[mlflow] tagging the version with an alias 'champion'"
curl -sS -X POST "${api}/registered-models/alias" -H 'Content-Type: application/json' \
  -d "{\"name\":\"${MODEL}\",\"alias\":\"champion\",\"version\":\"${VERSION}\"}" >/dev/null 2>&1 || true

echo "[mlflow] reading the model back from the registry"
GOT=$(curl -sS "${api}/registered-models/get?name=${MODEL}" \
  | jq -r '.registered_model.name')
echo "[mlflow] registry returned name = ${GOT}"
test "${GOT}" = "${MODEL}"

# The alias should resolve to the version we just created (best-effort: older
# servers may not support aliases — fall back to the latest_versions list).
ALIAS_VER=$(curl -sS "${api}/registered-models/alias?name=${MODEL}&alias=champion" \
  | jq -r '.model_version.version // empty' 2>/dev/null || true)
if [ -z "${ALIAS_VER}" ]; then
  ALIAS_VER=$(curl -sS "${api}/registered-models/get?name=${MODEL}" \
    | jq -r '.registered_model.latest_versions[-1].version')
fi
echo "[mlflow] resolved version = ${ALIAS_VER}"
test "${ALIAS_VER}" = "${VERSION}"

echo "[mlflow] OK — model registered, versioned and read back from the MLflow Model Registry."
