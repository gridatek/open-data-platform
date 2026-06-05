#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Prove Spark writes the shared Iceberg catalog on a cluster, and Trino reads it.
#
# Assumes the lakehouse (minio + iceberg-rest + trino) and Spark (the
# spark-iceberg runtime, its `demo` catalog wired to iceberg-rest + minio) are
# installed in namespace $NS and Ready.
#
# Writes demo.smoke.events through Spark (spark-sql, local mode), then asserts
# Trino sees the same table as iceberg.smoke.events with 4 rows.
#
#   NS  default odp
# ───────────────────────────────────────────────────────────────
set -euo pipefail

NS="${NS:-odp}"

coord() { kubectl -n "$NS" get pod -l app.kubernetes.io/component=coordinator -o name | head -1; }
spark() { kubectl -n "$NS" get pod -l app.kubernetes.io/name=spark -o name | head -1; }

echo "[proof] waiting for Spark to be Ready ..."
kubectl -n "$NS" rollout status deploy/spark --timeout=300s

echo "[proof] writing the Iceberg table through Spark (spark-sql → demo.smoke.events) ..."
kubectl -n "$NS" exec -i "$(spark)" -- spark-sql -e "
CREATE SCHEMA IF NOT EXISTS demo.smoke;
CREATE TABLE IF NOT EXISTS demo.smoke.events (id bigint, kind string, ts timestamp) USING iceberg;
DELETE FROM demo.smoke.events;
INSERT INTO demo.smoke.events VALUES
  (1, 'click',    TIMESTAMP'2026-06-01 10:00:00'),
  (2, 'view',     TIMESTAMP'2026-06-01 10:01:30'),
  (3, 'click',    TIMESTAMP'2026-06-01 10:02:15'),
  (4, 'purchase', TIMESTAMP'2026-06-01 10:05:00');
"

echo "[proof] asserting Trino reads the Spark-written table (== 4) ..."
OUT=$(kubectl -n "$NS" exec -i "$(coord)" -- trino --execute \
  "SELECT count(*) FROM iceberg.smoke.events" | tr -d '"[:space:]')
echo "rows: ${OUT}"
test "${OUT}" = "4"

echo "[proof] OK — Spark wrote the Iceberg table and Trino reads it, on Kubernetes."
