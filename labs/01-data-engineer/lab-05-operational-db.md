# 01 Data Engineer — Lab 5: The operational counterpart (HBase + Phoenix)

**Time:** ~20 min · **Prereqs:** `make opdb`, `cd quickstart`

## Goal

The Iceberg lakehouse (Labs 1–4) is built for **scans** — read a lot, append a
lot, time-travel. But some workloads need **random access by key**: look up *one*
row, update *one* row, fast. That's an **operational database**. Here you'll use
**HBase** (a wide-column store) with **Phoenix** (a SQL layer over it) to build a
key-addressed table and feel how it differs from the analytical lakehouse.

> Note: the Operational DB is **standalone** — it is *not* governed by the SDX
> layer (Iceberg/Ranger/Atlas). It's a different store for a different access
> pattern, which is exactly the point of this lab.

## Steps

1. **Bring up the Operational DB and confirm it's ready.**

   ```bash
   make opdb                          # HBase + Phoenix, Phoenix Query Server on :8765
   ../platform/opdb/smoke.sh          # waits for HBase, runs a create/upsert/select
   ```

   The smoke also bootstraps Phoenix's `SYSTEM.CATALOG` on first connect, so the
   shell in the next step connects instantly.

   > **On open-source:** a single-node HBase + Phoenix all-in-one container.
   > **On real CDP:** **Cloudera Operational Database (COD)** — managed HBase with
   > the Phoenix SQL/JDBC layer, for low-latency operational apps.

2. **Open a Phoenix SQL shell.**

   ```bash
   docker compose -f docker-compose.opdb.yml exec opdb \
     bash -lc 'HBASE_CONF_DIR=/opt/hbase/conf /opt/phoenix-server/bin/sqlline.py localhost:2181'
   ```

   (`HBASE_CONF_DIR` lets the client match the server's namespace-mapping setting;
   the fat client talks straight to HBase via ZooKeeper.)

3. **Create a key-addressed table and write some rows.** In `sqlline`:

   ```sql
   CREATE TABLE IF NOT EXISTS customers (
     id    INTEGER PRIMARY KEY,
     name  VARCHAR,
     tier  VARCHAR
   );
   UPSERT INTO customers VALUES (1, 'ana', 'free');
   UPSERT INTO customers VALUES (2, 'ben', 'pro');
   ```

   The `PRIMARY KEY` *is* the HBase row key — how rows are physically addressed.

4. **Point-lookup by key** — the operational read:

   ```sql
   SELECT * FROM customers WHERE id = 1;
   ```

   This is a single-row fetch by row key, not a scan.

   > **On open-source:** HBase seeks straight to the row by key — O(1)-ish,
   > millisecond latency, regardless of table size.
   > **On real CDP:** the same `WHERE pk = ...` point-get backs operational apps
   > (serving layers, profile stores) on COD.

5. **Upsert = insert *or* update by key.** Re-write the same key:

   ```sql
   UPSERT INTO customers VALUES (1, 'ana', 'pro');
   SELECT tier FROM customers WHERE id = 1;
   ```

   `ana` is now `pro` — no separate `UPDATE`, no new snapshot. Contrast Lab 4's
   Iceberg `MERGE INTO`, which rewrites data files and creates a snapshot. Type
   `!quit` to exit.

## Check yourself

- [ ] `../platform/opdb/smoke.sh` prints `OK` (HBase + Phoenix up) (step 1).
- [ ] `SELECT * FROM customers WHERE id = 1` returns exactly one row (step 4).
- [ ] After the second upsert, `tier` for `id = 1` is `pro` (step 5).

## Going further

- Think about *when* you'd choose each: operational point-access (HBase/Phoenix)
  vs analytical scan + time-travel (Iceberg/Trino). Most platforms run both.
- A pipeline often **serves** aggregates from an operational store that it
  **computes** in the lakehouse — Spark writes a summary table here by key.
- Back to the analytical track: [Lab 1 — ingest & transform](lab-01-spark-transform.md).
