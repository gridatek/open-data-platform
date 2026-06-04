#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Column-masking proof against the umbrella deployed on a cluster.
#
# Assumes the governance stack (minio + iceberg-rest + trino with the Ranger
# plugin + ranger) is installed in namespace $NS and Ready. Loads the Ranger
# policies, seeds the demo table through Trino (as admin), then asserts admin
# sees the real value while analyst sees it masked.
#
#   NS  default odp
# ───────────────────────────────────────────────────────────────
set -euo pipefail

NS="${NS:-odp}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

coord() { kubectl -n "$NS" get pod -l app.kubernetes.io/component=coordinator -o name | head -1; }
trino_exec() { kubectl -n "$NS" exec -i "$(coord)" -- trino "$@"; }

echo "[proof] port-forwarding ranger-admin:6080 ..."
kubectl -n "$NS" port-forward svc/ranger-admin 6080:6080 >/tmp/ranger-pf.log 2>&1 &
PF=$!
trap 'kill ${PF} 2>/dev/null || true' EXIT
for i in $(seq 1 40); do
  curl -sf -u "admin:rangerR0cks!" http://localhost:6080/service/public/v2/api/service >/dev/null 2>&1 && break
  sleep 3
done

echo "[proof] loading Ranger policies (service + analyst user + access/mask/impersonate/queryid)"
RANGER_URL=http://localhost:6080 bash "${REPO_ROOT}/platform/governance/load-policies.sh"
echo "[proof] letting the Trino plugin poll ..."; sleep 45

echo "[proof] seeding iceberg.smoke.events through Trino (admin)"
trino_exec --user admin --execute "
CREATE SCHEMA IF NOT EXISTS iceberg.smoke;
CREATE TABLE IF NOT EXISTS iceberg.smoke.events (id bigint, kind varchar, ts timestamp(6));
DELETE FROM iceberg.smoke.events;
INSERT INTO iceberg.smoke.events VALUES
  (1, 'click',    TIMESTAMP '2026-06-01 10:00:00'),
  (4, 'purchase', TIMESTAMP '2026-06-01 10:05:00');
"
sleep 20

echo "[proof] admin sees the real value"
OUT=$(trino_exec --user admin --execute "SELECT kind FROM iceberg.smoke.events WHERE id = 4" | tr -d '"[:space:]')
echo "admin sees: ${OUT}"
test "${OUT}" = "purchase"

echo "[proof] analyst sees the value masked"
OUT=$(trino_exec --user analyst --execute "SELECT kind FROM iceberg.smoke.events WHERE id = 4" | tr -d '"[:space:]')
echo "analyst sees: ${OUT}"
test "${OUT}" = "xxxxxxxx"

echo "[proof] OK — Ranger column masking enforced through Trino on Kubernetes."
