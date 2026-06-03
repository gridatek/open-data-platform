#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Register the Trino service in Ranger and load the column-mask policy.
#
#   RANGER_URL  default http://localhost:6080
#   RANGER_AUTH default admin:rangerR0cks!
#
# Usage:  ./load-policies.sh
# ───────────────────────────────────────────────────────────────
set -euo pipefail

RANGER_URL="${RANGER_URL:-http://localhost:6080}"
RANGER_AUTH="${RANGER_AUTH:-admin:rangerR0cks!}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

api() {
  # api <METHOD> <PATH> <json-file>
  curl -sS -u "${RANGER_AUTH}" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -X "$1" "${RANGER_URL}$2" \
    --data-binary "@$3"
}

echo "[policies] waiting for Ranger admin at ${RANGER_URL} ..."
until curl -sf -u "${RANGER_AUTH}" "${RANGER_URL}/service/public/v2/api/service" >/dev/null; do
  sleep 3
done

echo "[policies] creating Trino service 'trino-odp' (ignore 'already exists')"
api POST "/service/public/v2/api/service" "${HERE}/policies/trino-service.json" || true
echo

echo "[policies] applying base access policy (admin + analyst select)"
api POST "/service/public/v2/api/policy" "${HERE}/policies/trino-access.json" \
  || api PUT "/service/public/v2/api/policy/service/trino-odp/name/allow-select-events" \
        "${HERE}/policies/trino-access.json"
echo

echo "[policies] applying masking policy for iceberg.smoke.events.kind"
# create-or-update by service+policy name
api POST "/service/public/v2/api/policy" "${HERE}/policies/trino-events-mask.json" \
  || api PUT "/service/public/v2/api/policy/service/trino-odp/name/mask-events-kind-for-analyst" \
        "${HERE}/policies/trino-events-mask.json"
echo
echo "[policies] done. Allow ~30s for the Trino plugin to poll the new policy."
