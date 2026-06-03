# 01 Data Engineer — Lab 1: Ingest & transform with Spark

**Time:** ~25 min · **Prereqs:** `make core`, `cd quickstart`

## Goal

Do the core engineering loop: land **raw** data, transform it into a **curated**
table with Spark SQL, and confirm a different engine (Trino) reads your output.

Open a Spark SQL shell (everything below runs inside it):

```bash
docker compose exec spark spark-sql
```

## Steps

1. **Create a raw landing table** and load some messy rows.

   ```sql
   CREATE NAMESPACE IF NOT EXISTS demo.de;

   CREATE TABLE demo.de.raw_events (
     id     BIGINT,
     kind   STRING,
     region STRING,
     ts     STRING            -- raw: timestamps arrive as strings
   ) USING iceberg;

   INSERT INTO demo.de.raw_events VALUES
     (1,'click','eu','2026-06-01 09:00:00'),
     (2,'PURCHASE','us','2026-06-01 09:05:00'),
     (3,'view','US','2026-06-01 09:10:00'),
     (4,'purchase','eu','not-a-date'),
     (5,'click','apac','2026-06-01 09:20:00');
   ```

   > **On open-source:** Spark writes Iceberg through the REST catalog.
   > **On real CDP:** a CDE Spark job lands raw data in SDX storage.

2. **Transform into a curated table** — normalize case, parse timestamps, drop
   bad rows — with a single `CREATE TABLE AS SELECT`:

   ```sql
   CREATE TABLE demo.de.events_clean USING iceberg AS
   SELECT
     id,
     lower(kind)               AS kind,
     upper(region)             AS region,
     CAST(ts AS TIMESTAMP)     AS event_ts
   FROM demo.de.raw_events
   WHERE CAST(ts AS TIMESTAMP) IS NOT NULL;     -- drops the 'not-a-date' row
   ```

3. **Verify the transform.**

   ```sql
   SELECT kind, region, event_ts FROM demo.de.events_clean ORDER BY id;
   ```

   You should see 4 rows (row 4 dropped), `kind` lowercased, `region` uppercased.

   > **On real CDP:** this normalize-and-curate step is the bread-and-butter CDE
   > exam objective — build a managed Iceberg table from raw input.

4. **Append more data idempotently.** Exit Spark (`!quit`) and re-run with an
   incremental batch, then re-query:

   ```sql
   INSERT INTO demo.de.events_clean
   SELECT 6, 'view', 'EU', TIMESTAMP '2026-06-01 10:00:00';
   ```

5. **Read your output from Trino** (different engine, same table):

   ```bash
   docker compose exec trino trino \
     --execute "SELECT count(*) FROM iceberg.de.events_clean"
   ```

   Returns 5. Spark wrote it; Trino reads it; no copy.

## Check yourself

- [ ] `events_clean` has 4 rows after step 2 (the bad-timestamp row is gone).
- [ ] After the append it has 5, and Trino agrees (step 5).
- [ ] `kind` is lowercase and `region` uppercase.

## Going further

- Re-implement the transform as a `spark-submit` job file (mirror
  `spark/jobs/seed_lakehouse.py`) so Airflow can run it in Lab 3.
- Next: [Lab 2 — maintain Iceberg tables](lab-02-iceberg-maintenance.md).
