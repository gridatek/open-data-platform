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
  # --fail-with-body: return non-zero on HTTP >= 400 *and* still print the body,
  # so a rejected policy aborts the script (set -e) instead of being swallowed.
  curl -sS --fail-with-body -u "${RANGER_AUTH}" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -X "$1" "${RANGER_URL}$2" \
    --data-binary "@$3"
}

# Ranger refuses to create a policy that references a user it doesn't know about
# ("User name: <x> ... does not exist in ranger admin"), so every user named in a
# policy item must exist first. 'admin' is built in; demo users are created here.
ensure_user() {
  # ensure_user <name>
  local name="$1"
  if curl -sf -u "${RANGER_AUTH}" \
       "${RANGER_URL}/service/xusers/users/userName/${name}" >/dev/null 2>&1; then
    echo "[policies] Ranger user '${name}' already exists"
    return 0
  fi
  echo "[policies] creating Ranger user '${name}'"
  curl -sS --fail-with-body -u "${RANGER_AUTH}" \
    -H 'Content-Type: application/json' -H 'Accept: application/json' \
    -X POST "${RANGER_URL}/service/xusers/secure/users" \
    --data-binary "{\"name\":\"${name}\",\"password\":\"Odp@Secret123\",\"firstName\":\"${name}\",\"lastName\":\"odp\",\"emailAddress\":\"\",\"userRoleList\":[\"ROLE_USER\"]}" \
    >/dev/null
  # Confirm it landed — fail loudly otherwise.
  curl -sf -u "${RANGER_AUTH}" \
    "${RANGER_URL}/service/xusers/users/userName/${name}" >/dev/null
}

echo "[policies] waiting for Ranger admin at ${RANGER_URL} ..."
until curl -sf -u "${RANGER_AUTH}" "${RANGER_URL}/service/public/v2/api/service" >/dev/null; do
  sleep 3
done

echo "[policies] creating Trino service 'trino-odp' (ignore 'already exists')"
api POST "/service/public/v2/api/service" "${HERE}/policies/trino-service.json" || true
echo

# Users referenced by the policies below must exist in Ranger first.
ensure_user analyst
echo

echo "[policies] applying base access policy (admin + analyst select)"
api POST "/service/public/v2/api/policy" "${HERE}/policies/trino-access.json" \
  || api PUT "/service/public/v2/api/policy/service/trino-odp/name/allow-select-events" \
        "${HERE}/policies/trino-access.json"
echo

echo "[policies] allowing analyst to set its own Trino session user (impersonation)"
api POST "/service/public/v2/api/policy" "${HERE}/policies/trino-impersonation.json" \
  || api PUT "/service/public/v2/api/policy/service/trino-odp/name/allow-analyst-self-impersonation" \
        "${HERE}/policies/trino-impersonation.json"
echo

echo "[policies] allowing analyst to execute queries"
api POST "/service/public/v2/api/policy" "${HERE}/policies/trino-query.json" \
  || api PUT "/service/public/v2/api/policy/service/trino-odp/name/allow-analyst-execute-query" \
        "${HERE}/policies/trino-query.json"
echo

echo "[policies] applying masking policy for iceberg.smoke.events.kind"
# create-or-update by service+policy name
api POST "/service/public/v2/api/policy" "${HERE}/policies/trino-events-mask.json" \
  || api PUT "/service/public/v2/api/policy/service/trino-odp/name/mask-events-kind-for-analyst" \
        "${HERE}/policies/trino-events-mask.json"
echo
echo "[policies] done. Allow ~30s for the Trino plugin to poll the new policy."
