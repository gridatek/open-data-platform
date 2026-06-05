#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Run the lakehouse_smoke DAG against the umbrella deployed on a cluster, and
# assert it wrote the governed table through Trino.
#
# Assumes the lakehouse (minio + iceberg-rest + trino) and Airflow (our
# 3.2.0 + Trino-provider image, LocalExecutor, the git-synced DAG) are installed
# in namespace $NS and Ready.
#
#   NS  default odp
# ───────────────────────────────────────────────────────────────
set -euo pipefail

NS="${NS:-odp}"

coord() { kubectl -n "$NS" get pod -l app.kubernetes.io/component=coordinator -o name | head -1; }
sched() { kubectl -n "$NS" get pod -l component=scheduler -o name | head -1; }

echo "[proof] waiting for the Airflow scheduler to be Ready ..."
kubectl -n "$NS" wait --for=condition=ready pod -l component=scheduler --timeout=300s

echo "[proof] running lakehouse_smoke end-to-end (airflow dags test) ..."
# extract -> load (Trino write) -> verify (SQLValueCheck count == 4). `dags test`
# runs synchronously and exits non-zero if any task fails.
kubectl -n "$NS" exec -i "$(sched)" -c scheduler -- \
  airflow dags test lakehouse_smoke 2026-06-01

echo "[proof] asserting the governed table has 4 rows (via Trino) ..."
OUT=$(kubectl -n "$NS" exec -i "$(coord)" -- trino --execute \
  "SELECT count(*) FROM iceberg.smoke.events" | tr -d '"[:space:]')
echo "rows: ${OUT}"
test "${OUT}" = "4"

echo "[proof] OK — Airflow ran the real Trino operators on Kubernetes."
