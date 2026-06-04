#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Operational DB smoke test — prove HBase + Phoenix work:
# create a Phoenix table, upsert rows, read one back.
#
#   OPDB_CONTAINER  default odp-opdb
#
# Usage:  ./smoke.sh
# ───────────────────────────────────────────────────────────────
set -euo pipefail

OPDB_CONTAINER="${OPDB_CONTAINER:-odp-opdb}"

# Phoenix fat client → ZooKeeper. HBASE_CONF_DIR points at the server's config so
# the client's phoenix.schema.isNamespaceMappingEnabled matches the server (else
# ERROR 726). The thin client (sqlline-thin/PQS) is broken in this image.
phoenix_sql() {
  docker exec -i "${OPDB_CONTAINER}" bash -c \
    'export HBASE_CONF_DIR=/opt/hbase/conf; /opt/phoenix-server/bin/sqlline.py localhost:2181 2>/dev/null'
}

echo "[opdb] waiting for HBase + Phoenix (region assignment + SYSTEM.CATALOG bootstrap)..."
# The first successful Phoenix connection bootstraps the SYSTEM tables; that can't
# happen until HBase has assigned its regions, so retry the whole exchange.
OUT=""
for i in $(seq 1 40); do
  OUT=$(phoenix_sql <<'SQL' || true
CREATE TABLE IF NOT EXISTS odp_events (id INTEGER PRIMARY KEY, kind VARCHAR);
UPSERT INTO odp_events VALUES (1, 'purchase');
UPSERT INTO odp_events VALUES (2, 'refund');
SELECT kind FROM odp_events WHERE id = 1;
!quit
SQL
)
  if echo "$OUT" | grep -q "purchase"; then
    echo "[opdb] Phoenix ready (after ${i} attempts)"
    break
  fi
  echo "[opdb] not ready yet (${i})..."; sleep 10
done

echo "[opdb] query result:"
echo "$OUT" | grep -iE "kind|purchase" | head

if echo "$OUT" | grep -q "purchase"; then
  echo "[opdb] OK — Phoenix created a table and read back the expected value."
else
  echo "[opdb] FAIL — never read back 'purchase'. Full output:" >&2
  echo "$OUT" >&2
  exit 1
fi
