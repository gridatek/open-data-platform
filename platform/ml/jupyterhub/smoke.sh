#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# JupyterHub smoke test — prove the hub is up and can spawn a
# single-user notebook server.
#
#   HUB_URL    default http://localhost:8000
#   HUB_TOKEN  default odp-smoke-token (the admin API token in the config)
#   HUB_USER   default demo
#
# Usage:  ./smoke.sh        (requires curl, jq)
# ───────────────────────────────────────────────────────────────
set -euo pipefail

HUB_URL="${HUB_URL:-http://localhost:8000}"
TOKEN="${HUB_TOKEN:-odp-smoke-token}"
USER="${HUB_USER:-demo}"
AUTH=(-H "Authorization: token ${TOKEN}")

echo "[jupyterhub] waiting for the hub at ${HUB_URL} ..."
for i in $(seq 1 60); do
  if curl -sf "${HUB_URL}/hub/api/" >/dev/null 2>&1; then
    echo "[jupyterhub] hub up — version $(curl -sf "${HUB_URL}/hub/api/" | jq -r .version)"
    break
  fi
  sleep 5
done

echo "[jupyterhub] creating user '${USER}'"
curl -sf -X POST "${AUTH[@]}" "${HUB_URL}/hub/api/users/${USER}" >/dev/null 2>&1 || true

echo "[jupyterhub] starting ${USER}'s notebook server"
code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "${AUTH[@]}" \
  "${HUB_URL}/hub/api/users/${USER}/server")
echo "[jupyterhub] POST .../server -> HTTP ${code}"

echo "[jupyterhub] waiting for the server to be ready"
for i in $(seq 1 36); do
  ready=$(curl -sf "${AUTH[@]}" "${HUB_URL}/hub/api/users/${USER}" \
            | jq -r '.servers[""].ready // false')
  echo "  ready=${ready} (${i})"
  if [ "${ready}" = "true" ]; then
    echo "[jupyterhub] OK — JupyterHub spawned a notebook server for '${USER}'."
    exit 0
  fi
  sleep 5
done

echo "[jupyterhub] FAIL — server never became ready." >&2
curl -s "${AUTH[@]}" "${HUB_URL}/hub/api/users/${USER}" >&2
exit 1
