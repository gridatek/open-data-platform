#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Prove the Knox perimeter works on a cluster:
#   1. the gateway is up and terminates TLS on :8443,
#   2. it rejects an unauthenticated request at the edge (HTTP 401),
#   3. it authenticates a demo-LDAP user and proxies through to a backend
#      (admin / admin-password → 200 from the in-cluster Trino Service).
#
# Assumes the lakehouse (Trino at least) and Knox (knox.enabled=true) are
# installed in namespace $NS and Ready.
#
#   NS  default odp
# ───────────────────────────────────────────────────────────────
set -euo pipefail

NS="${NS:-odp}"
# /v1/info is Trino's lightweight, unauthenticated readiness endpoint (200 + JSON
# version) — a clean "did Knox reach Trino?" signal. It works through the gateway
# once Trino is told to accept Knox's X-Forwarded-* headers
# (http-server.process-forwarded=true, set in kind-knox-values.yaml); without that
# Trino answers every proxied request with 406.
BASE="https://localhost:8443/gateway/odp/trino/v1/info"

echo "[proof] waiting for knox to be Ready ..."
kubectl -n "$NS" rollout status deploy/knox --timeout=300s

echo "[proof] port-forwarding knox:8443 ..."
kubectl -n "$NS" port-forward svc/knox 8443:8443 >/tmp/knox-pf.log 2>&1 &
PF=$!
trap 'kill ${PF} 2>/dev/null || true' EXIT

# Wait until the gateway answers TLS at all (any HTTP status = listening).
for i in $(seq 1 40); do
  curl -sk -o /dev/null "$BASE" && break
  sleep 3
done

echo "[proof] unauthenticated request is rejected at the edge (expect 401) ..."
code=$(curl -sk -o /dev/null -w '%{http_code}' "$BASE")
echo "  no-auth status: ${code}"
test "${code}" = "401"

echo "[proof] authenticated request is proxied to the Trino backend (expect 200) ..."
# Retry: Trino may still be warming up behind the gateway.
for i in $(seq 1 40); do
  code=$(curl -sk -o /dev/null -w '%{http_code}' -u admin:admin-password "$BASE")
  echo "  admin status: ${code} (${i})"
  if [ "${code}" = "200" ]; then
    echo "[proof] OK — Knox rejected anonymous access (401) and proxied an authenticated user through to Trino (200)."
    exit 0
  fi
  sleep 3
done

echo "[proof] FAIL — authenticated request never reached Trino through the gateway." >&2
echo "[proof] last response (status + headers + body head) for diagnosis:" >&2
curl -isk -u admin:admin-password "$BASE" 2>&1 | head -40 >&2 || true
exit 1
