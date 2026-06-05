#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Prove the console control plane works on a cluster:
#   1. it's up and reports service health (GET /api/services),
#   2. it browses the shared Iceberg REST catalog (GET /api/catalog/namespaces),
#   3. it can scale a Deployment through the K8s API (the RBAC control plane).
#
# Assumes the lakehouse (minio + iceberg-rest + trino) and the console
# (console-api, odp.k8s.enabled=true + its ServiceAccount/RBAC) are installed in
# namespace $NS and Ready.
#
#   NS  default odp
# ───────────────────────────────────────────────────────────────
set -euo pipefail

NS="${NS:-odp}"

coord() { kubectl -n "$NS" get pod -l app.kubernetes.io/component=coordinator -o name | head -1; }

echo "[proof] waiting for console-api to be Ready ..."
kubectl -n "$NS" rollout status deploy/console-api --timeout=300s

echo "[proof] seeding iceberg.smoke.events through Trino (so the catalog has a namespace) ..."
kubectl -n "$NS" exec -i "$(coord)" -- trino --execute "
CREATE SCHEMA IF NOT EXISTS iceberg.smoke;
CREATE TABLE IF NOT EXISTS iceberg.smoke.events (id bigint, kind varchar);
"

echo "[proof] port-forwarding console-api:8090 ..."
kubectl -n "$NS" port-forward svc/console-api 8090:8090 >/tmp/console-pf.log 2>&1 &
PF=$!
trap 'kill ${PF} 2>/dev/null || true' EXIT
for i in $(seq 1 40); do
  curl -sf http://localhost:8090/api/services >/dev/null 2>&1 && break
  sleep 3
done

echo "[proof] GET /api/services — console up and reporting health ..."
n=$(curl -sf http://localhost:8090/api/services | jq 'length')
echo "  services reported: ${n}"
test "${n}" -ge 1

echo "[proof] GET /api/catalog/namespaces — console reads the Iceberg REST catalog ..."
ns=$(curl -sf http://localhost:8090/api/catalog/namespaces)
echo "  namespaces: ${ns}"
echo "${ns}" | grep -q smoke

echo "[proof] control plane: POST /api/services/iceberg-rest/scale {replicas:2} ..."
curl -sf -X POST -H 'Content-Type: application/json' -d '{"replicas":2}' \
  http://localhost:8090/api/services/iceberg-rest/scale

echo "[proof] verify the Deployment scaled through the K8s API (RBAC works) ..."
for i in $(seq 1 20); do
  r=$(kubectl -n "$NS" get deploy iceberg-rest -o jsonpath='{.spec.replicas}')
  echo "  iceberg-rest spec.replicas=${r} (${i})"
  if [ "${r}" = "2" ]; then
    echo "[proof] OK — console reported health, read the catalog, and scaled a Deployment on Kubernetes."
    exit 0
  fi
  sleep 3
done

echo "[proof] FAIL — iceberg-rest never scaled to 2." >&2
exit 1
