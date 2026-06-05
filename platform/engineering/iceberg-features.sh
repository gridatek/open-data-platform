#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Iceberg feature demo + proof. Runs the Spark feature job (partitioning, MERGE
# upserts, schema evolution) and then demonstrates time-travel through Trino
# against the same table. Backs data-engineer lab-02 / lab-04.
#
# Run from quickstart/ with the lakehouse (spark + trino) up. Requires docker compose.
# ───────────────────────────────────────────────────────────────
set -euo pipefail

DC="docker compose"

echo "[features] partitioning + MERGE upsert + schema evolution (Spark) ..."
${DC} exec -T spark spark-submit /home/iceberg/jobs/iceberg_features.py 2>&1 | grep '\[iceberg\]'

echo "[features] time-travel through Trino (iceberg.de.events_clean) ..."
SNAP=$(${DC} exec -T trino trino --execute \
  'SELECT snapshot_id FROM iceberg.de."events_clean$snapshots" ORDER BY committed_at ASC LIMIT 1' \
  | tr -d '"[:space:]')
PAST=$(${DC} exec -T trino trino --execute \
  "SELECT count(*) FROM iceberg.de.events_clean FOR VERSION AS OF ${SNAP}" | tr -d '"[:space:]')
CUR=$(${DC} exec -T trino trino --execute \
  "SELECT count(*) FROM iceberg.de.events_clean" | tr -d '"[:space:]')
echo "[features] oldest snapshot had ${PAST} rows; current has ${CUR} rows"

# time-travel must show a real earlier state: 3 rows then, 5 now.
test "${PAST}" = "3"
test "${CUR}" = "5"

echo "[features] OK — partitioning, MERGE upserts, schema evolution, and time-travel."
