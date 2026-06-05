#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Prove Superset can query the governed Iceberg table through Trino on a cluster.
#
# Assumes the lakehouse (minio + iceberg-rest + trino) and Superset (our
# Trino-dialect image, metadata in the bundled Postgres, the trino-odp connection
# seeded at init) are installed in namespace $NS and Ready.
#
# Seeds iceberg.smoke.events through Trino (as Superset is a read-only consumer),
# then drives the Superset API to run `SELECT count(*)` through the Trino
# connection and asserts it returns 4.
#
#   NS  default odp
# ───────────────────────────────────────────────────────────────
set -euo pipefail

NS="${NS:-odp}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

coord() { kubectl -n "$NS" get pod -l app.kubernetes.io/component=coordinator -o name | head -1; }

echo "[proof] seeding iceberg.smoke.events through Trino ..."
kubectl -n "$NS" exec -i "$(coord)" -- trino --execute "
CREATE SCHEMA IF NOT EXISTS iceberg.smoke;
CREATE TABLE IF NOT EXISTS iceberg.smoke.events (id bigint, kind varchar, ts timestamp(6));
DELETE FROM iceberg.smoke.events;
INSERT INTO iceberg.smoke.events VALUES
  (1, 'click',    TIMESTAMP '2026-06-01 10:00:00'),
  (2, 'view',     TIMESTAMP '2026-06-01 10:01:30'),
  (3, 'click',    TIMESTAMP '2026-06-01 10:02:15'),
  (4, 'purchase', TIMESTAMP '2026-06-01 10:05:00');
"

echo "[proof] waiting for Superset to be Ready ..."
kubectl -n "$NS" rollout status deploy/odp-superset --timeout=300s

echo "[proof] port-forwarding odp-superset:8088 ..."
kubectl -n "$NS" port-forward svc/odp-superset 8088:8088 >/tmp/superset-pf.log 2>&1 &
PF=$!
trap 'kill ${PF} 2>/dev/null || true' EXIT
for i in $(seq 1 40); do
  curl -sf http://localhost:8088/health >/dev/null 2>&1 && break
  sleep 3
done

echo "[proof] driving Superset → Trino through the API (asserts count == 4) ..."
SUPERSET_URL=http://localhost:8088 bash "${REPO_ROOT}/platform/viz/register-trino.sh"

echo "[proof] OK — Superset queried the governed Iceberg table through Trino on Kubernetes."
