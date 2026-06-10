#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Prove Hue works on a cluster:
#   1. the SQL editor is up and serving (GET /desktop/debug/is_alive → 200),
#   2. its config carries the Trino interpreter pointed at the in-cluster
#      `trino` Service (so the editor can query the governed lakehouse).
#
# Assumes Hue (hue.enabled=true) and the lakehouse (Trino) are installed in
# namespace $NS and Ready.
#
#   NS  default odp
# ───────────────────────────────────────────────────────────────
set -euo pipefail

NS="${NS:-odp}"

echo "[proof] waiting for hue to be Ready ..."
kubectl -n "$NS" rollout status deploy/hue --timeout=420s

echo "[proof] config carries the Trino interpreter ..."
kubectl -n "$NS" get configmap hue -o jsonpath='{.data.z-hue\.ini}' | grep -q 'interface=trino'
kubectl -n "$NS" get configmap hue -o jsonpath='{.data.z-hue\.ini}' | grep -q 'http://trino:8080'
echo "  trino interpreter present ✓"

echo "[proof] port-forwarding hue:8888 ..."
kubectl -n "$NS" port-forward svc/hue 8888:8888 >/tmp/hue-pf.log 2>&1 &
PF=$!
trap 'kill ${PF} 2>/dev/null || true' EXIT

echo "[proof] GET /desktop/debug/is_alive — editor is up (expect 200) ..."
for i in $(seq 1 40); do
  code=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8888/desktop/debug/is_alive || true)
  echo "  is_alive status: ${code} (${i})"
  if [ "${code}" = "200" ]; then
    echo "[proof] OK — Hue is serving and its Trino interpreter is wired to the lakehouse."
    exit 0
  fi
  sleep 3
done

echo "[proof] FAIL — Hue never reported alive." >&2
exit 1
