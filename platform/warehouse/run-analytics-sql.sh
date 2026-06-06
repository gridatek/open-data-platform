#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Build the analyst's `orders` dataset in Trino and assert the Lab 1 analytics
# (aggregate, join, window) return the expected answers — the runnable,
# CI-proven backing for labs/02-data-analyst/lab-01-sql-on-trino.md.
#
# Trino writes Iceberg DDL/DML through the REST catalog (catalog `iceberg`),
# so this is real warehouse SQL, not a fixture. Idempotent: drops and rebuilds.
#
#   TRINO   how to invoke the Trino CLI
#           (default: docker compose exec -T trino trino)
#
# Usage:  ./run-analytics-sql.sh
# ───────────────────────────────────────────────────────────────
set -euo pipefail

TRINO=${TRINO:-docker compose exec -T trino trino}

# Run a single query as `admin` and strip Trino's quoting/whitespace.
q() { $TRINO --user admin --execute "$1" | tr -d '"[:space:]'; }

echo "[analytics] (re)building iceberg.analytics.orders + product_tier"
$TRINO --user admin <<'SQL'
CREATE SCHEMA IF NOT EXISTS iceberg.analytics;
DROP TABLE IF EXISTS iceberg.analytics.orders;
DROP TABLE IF EXISTS iceberg.analytics.product_tier;
CREATE TABLE iceberg.analytics.orders (
  id bigint, region varchar, product varchar, amount double, ts timestamp(6)
);
INSERT INTO iceberg.analytics.orders VALUES
  (1,'EU','widget',   19.99, TIMESTAMP '2026-06-01 09:00:00'),
  (2,'EU','gadget',   49.50, TIMESTAMP '2026-06-01 09:30:00'),
  (3,'US','widget',   21.00, TIMESTAMP '2026-06-01 10:00:00'),
  (4,'US','gizmo',   120.00, TIMESTAMP '2026-06-01 10:15:00'),
  (5,'US','gadget',   47.25, TIMESTAMP '2026-06-01 11:00:00'),
  (6,'APAC','widget', 18.75, TIMESTAMP '2026-06-01 11:30:00'),
  (7,'APAC','gizmo', 115.00, TIMESTAMP '2026-06-01 12:00:00'),
  (8,'EU','gizmo',   118.00, TIMESTAMP '2026-06-01 12:30:00'),
  (9,'US','widget',   20.50, TIMESTAMP '2026-06-01 13:00:00'),
  (10,'APAC','gadget',46.00, TIMESTAMP '2026-06-01 13:30:00');
CREATE TABLE iceberg.analytics.product_tier (product varchar, tier varchar);
INSERT INTO iceberg.analytics.product_tier VALUES
  ('widget','budget'), ('gadget','mid'), ('gizmo','premium');
SQL

echo "[analytics] step 2 — row count"
ROWS=$(q "SELECT count(*) FROM iceberg.analytics.orders")
echo "  rows = ${ROWS}"; test "${ROWS}" = "10"

echo "[analytics] step 3 — top region by revenue (GROUP BY)"
TOP_REGION=$(q "SELECT region FROM iceberg.analytics.orders
                GROUP BY region ORDER BY sum(amount) DESC LIMIT 1")
echo "  top region = ${TOP_REGION}"; test "${TOP_REGION}" = "US"

echo "[analytics] step 4 — top tier by revenue (JOIN)"
TOP_TIER=$(q "SELECT t.tier
              FROM iceberg.analytics.orders o
              JOIN iceberg.analytics.product_tier t ON o.product = t.product
              GROUP BY t.tier ORDER BY sum(o.amount) DESC LIMIT 1")
echo "  top tier = ${TOP_TIER}"; test "${TOP_TIER}" = "premium"

echo "[analytics] step 5 — window: each region's shares sum to ~100% (PARTITION BY)"
# round(sum of per-row pct_of_region) over 3 regions must be 300.
SHARES=$(q "SELECT round(sum(pct)) FROM (
              SELECT 100.0 * amount / sum(amount) OVER (PARTITION BY region) AS pct
              FROM iceberg.analytics.orders)")
echo "  sum of shares = ${SHARES}"; test "${SHARES}" = "300.0" -o "${SHARES}" = "300"

echo "[analytics] OK — Lab 1 analytics verified on Trino (US top region, premium top tier)"
