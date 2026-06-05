#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Prove Atlas comes up on a cluster and its health probes authenticate with the
# admin creds from the shared Secret (env, not a baked-in Basic-auth header).
#
# Assumes Atlas is installed in namespace $NS. `rollout status` only returns once
# the readiness exec-probe (wget /admin/version with $ATLAS_USER/$ATLAS_PASSWORD)
# passes, so reaching Ready already proves the creds work; the explicit query is
# belt-and-suspenders.
#
#   NS  default odp
# ───────────────────────────────────────────────────────────────
set -euo pipefail

NS="${NS:-odp}"

echo "[proof] waiting for Atlas to be Ready (exec probe uses Secret creds) ..."
kubectl -n "$NS" rollout status deploy/atlas --timeout=600s

echo "[proof] querying /api/atlas/admin/version with the creds from env ..."
pod=$(kubectl -n "$NS" get pod -l app.kubernetes.io/name=atlas -o name | head -1)
out=$(kubectl -n "$NS" exec -i "$pod" -- sh -c \
  'wget -qO- --user="$ATLAS_USER" --password="$ATLAS_PASSWORD" http://127.0.0.1:21000/api/atlas/admin/version')
echo "  atlas version: ${out}"
echo "${out}" | grep -q Version

echo "[proof] OK — Atlas is up and authenticated with creds from the Secret, on Kubernetes."
