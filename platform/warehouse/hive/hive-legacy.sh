#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# LEGACY lab — prove the old Hive path works, then migrate it to Iceberg.
#
# This is deliberately the OLD world: a Hive table in the Hive Metastore (HMS),
# data on MinIO/S3. We create it, query it from Trino's `hive` catalog, then
# do the one move that matters in CDP — copy it into an Iceberg table and show
# the row counts match. That CTAS is the essence of the Hive → Iceberg
# migration story.
#
# Prereqs: start the overlay first —
#   make hive
#
#   TRINO   how to invoke the Trino CLI
#           (default: docker compose -p odp-quickstart exec -T trino trino)
#
# Usage:  ./platform/warehouse/hive/hive-legacy.sh
# ───────────────────────────────────────────────────────────────
set -euo pipefail

TRINO=${TRINO:-docker compose -p odp-quickstart exec -T trino trino}

# Run a single query as `admin` and strip Trino's quoting/whitespace.
q() { $TRINO --user admin --execute "$1" | tr -d '"[:space:]'; }

# HMS can take a moment to open its Thrift port after the container starts.
echo "[hive] waiting for the Hive Metastore (catalog \`hive\`) to answer ..."
for i in $(seq 1 30); do
  if $TRINO --user admin --execute "SHOW SCHEMAS FROM hive" >/dev/null 2>&1; then
    break
  fi
  if [ "$i" = 30 ]; then
    echo "[hive] metastore never came up — is \`make hive\` running?" >&2
    exit 1
  fi
  sleep 5
done

echo "[hive] step 1 — create a LEGACY Hive table (HMS metadata, data on MinIO/S3)"
$TRINO --user admin <<'SQL'
CREATE SCHEMA IF NOT EXISTS hive.legacy
  WITH (location = 's3a://warehouse/hive/legacy');
DROP TABLE IF EXISTS hive.legacy.sales;
CREATE TABLE hive.legacy.sales (
  id bigint, region varchar, product varchar, amount double
)
WITH (format = 'PARQUET', external_location = 's3a://warehouse/hive/legacy/sales');
INSERT INTO hive.legacy.sales VALUES
  (1,'EU','widget',   19.99),
  (2,'EU','gadget',   49.50),
  (3,'US','widget',   21.00),
  (4,'US','gizmo',   120.00),
  (5,'APAC','gadget', 46.00);
SQL

echo "[hive] step 2 — query the Hive table from Trino"
ROWS=$(q "SELECT count(*) FROM hive.legacy.sales")
echo "  hive rows = ${ROWS}"; test "${ROWS}" = "5"

echo "[hive] step 3 — confirm it's really a HIVE table, not Iceberg"
KIND=$(q "SELECT table_type FROM hive.information_schema.tables
          WHERE table_schema = 'legacy' AND table_name = 'sales'")
echo "  table_type = ${KIND}"   # informational; HMS reports a Hive table type

echo "[hive] step 4 — MIGRATE: copy the Hive table into Iceberg (CTAS)"
# This is the move you'd make in CDP: lift legacy Hive data into the modern
# Iceberg format, where you get snapshots, time travel, and the REST catalog.
$TRINO --user admin <<'SQL'
CREATE SCHEMA IF NOT EXISTS iceberg.migrated;
DROP TABLE IF EXISTS iceberg.migrated.sales;
CREATE TABLE iceberg.migrated.sales AS
  SELECT * FROM hive.legacy.sales;
SQL

echo "[hive] step 5 — verify the migrated Iceberg table matches row-for-row"
ICE=$(q "SELECT count(*) FROM iceberg.migrated.sales")
SUM_HIVE=$(q "SELECT cast(round(sum(amount),2) as varchar) FROM hive.legacy.sales")
SUM_ICE=$(q "SELECT cast(round(sum(amount),2) as varchar) FROM iceberg.migrated.sales")
echo "  iceberg rows = ${ICE} (hive ${ROWS})        amount: hive=${SUM_HIVE} iceberg=${SUM_ICE}"
test "${ICE}" = "${ROWS}"
test "${SUM_ICE}" = "${SUM_HIVE}"

echo "[hive] OK — legacy Hive table queried, then migrated to Iceberg (counts + totals match)."
echo "[hive] takeaway: Hive still works behind Trino, but Iceberg is where new work goes."
