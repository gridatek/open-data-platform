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

# Some Trino checks (e.g. query execution) are governed by Ranger's auto-created
# default policies, which grant only the service admin. Ranger refuses a second
# policy with the same resource signature (e.g. queryid=*), so we can't add our
# own — instead extend the default policy in place to also grant 'analyst'.
grant_default_to_analyst() {
  # grant_default_to_analyst <policy-name> <access-type>
  # Look the policy up via the service's policy list (a known-good endpoint) and
  # match by exact name, rather than the flaky get-policy-by-name path.
  local pname="$1" access="$2" pol id
  pol=$(curl -sf -u "${RANGER_AUTH}" \
          "${RANGER_URL}/service/public/v2/api/service/trino-odp/policy" \
        | jq --arg n "$pname" 'map(select(.name == $n)) | .[0]')
  if [ -z "$pol" ] || [ "$pol" = "null" ]; then
    echo "[policies] ERROR: default policy '$pname' not found" >&2
    return 1
  fi
  id=$(printf '%s' "$pol" | jq -r '.id')
  printf '%s' "$pol" | jq --arg a "$access" '
      if any(.policyItems[]?; (.users | index("analyst")) and any(.accesses[]?; .type == $a))
      then .
      else .policyItems += [{"users":["analyst"],"groups":[],"roles":[],
                             "accesses":[{"type":$a,"isAllowed":true}],
                             "delegateAdmin":false}]
      end' \
    | curl -sS --fail-with-body -u "${RANGER_AUTH}" \
        -H 'Content-Type: application/json' -H 'Accept: application/json' \
        -X PUT "${RANGER_URL}/service/public/v2/api/policy/${id}" --data-binary @- >/dev/null
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

echo "[policies] granting analyst EXECUTE on queries (extend default 'all - queryid')"
grant_default_to_analyst "all - queryid" execute
echo

echo "[policies] applying masking policy for iceberg.smoke.events.kind"
# create-or-update by service+policy name
api POST "/service/public/v2/api/policy" "${HERE}/policies/trino-events-mask.json" \
  || api PUT "/service/public/v2/api/policy/service/trino-odp/name/mask-events-kind-for-analyst" \
        "${HERE}/policies/trino-events-mask.json"
echo
echo "[policies] done. Allow ~30s for the Trino plugin to poll the new policy."
