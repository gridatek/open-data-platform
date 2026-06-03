#!/usr/bin/env bash
# Render install.properties from env, run Ranger's setup, then start the admin.
set -euo pipefail

: "${RANGER_HOME:=/opt/ranger-admin}"
: "${RANGER_DB_HOST:=ranger-db}"
: "${RANGER_DB_PORT:=5432}"
: "${RANGER_DB_NAME:=ranger}"
: "${RANGER_DB_USER:=rangeradmin}"
: "${RANGER_DB_PASSWORD:=rangeradmin}"
: "${RANGER_ADMIN_PASSWORD:=rangerR0cks!}"

# Ensure the install user exists (Ranger's setup.sh chowns to it).
id ranger >/dev/null 2>&1 || useradd -r -m -d /home/ranger ranger

render() {
  sed \
    -e "s|__RANGER_DB_HOST__|${RANGER_DB_HOST}|g" \
    -e "s|__RANGER_DB_PORT__|${RANGER_DB_PORT}|g" \
    -e "s|__RANGER_DB_NAME__|${RANGER_DB_NAME}|g" \
    -e "s|__RANGER_DB_USER__|${RANGER_DB_USER}|g" \
    -e "s|__RANGER_DB_PASSWORD__|${RANGER_DB_PASSWORD}|g" \
    -e "s|__RANGER_ADMIN_PASSWORD__|${RANGER_ADMIN_PASSWORD}|g" \
    "${RANGER_HOME}/install.properties.tmpl" > "${RANGER_HOME}/install.properties"
}

echo "[ranger] waiting for ${RANGER_DB_HOST}:${RANGER_DB_PORT} ..."
until pg_isready -h "${RANGER_DB_HOST}" -p "${RANGER_DB_PORT}" -U "${RANGER_DB_USER}" >/dev/null 2>&1; do
  sleep 2
done

echo "[ranger] rendering install.properties"
render

echo "[ranger] running setup.sh (schema + config)"
cd "${RANGER_HOME}"
./setup.sh

echo "[ranger] starting admin on :6080"
ranger-admin start

# setup starts the admin in the background; keep the container alive and stream logs.
tail -F "${RANGER_HOME}/ews/logs/"*.log 2>/dev/null || tail -f /dev/null
