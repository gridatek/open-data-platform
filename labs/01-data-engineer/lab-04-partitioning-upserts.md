# 01 Data Engineer — Lab 4: Partitioning & upserts

**Time:** ~30 min · **Prereqs:** Lab 1 done, Spark SQL shell open
(`docker compose exec spark spark-sql`)

## Goal

Two production patterns: **hidden partitioning** (lay data out for fast queries
without leaking partition columns into your SQL) and **`MERGE INTO`** (upsert an
incremental batch instead of reloading the whole table).

## Steps

1. **Create a partitioned table** — partition by day of the event timestamp:

   ```sql
   CREATE TABLE demo.de.events_curated (
     id       BIGINT,
     kind     STRING,
     region   STRING,
     event_ts TIMESTAMP
   ) USING iceberg
   PARTITIONED BY (days(event_ts));
   ```

   `days(event_ts)` is **hidden partitioning** — Iceberg derives the partition
   from the column; queries filter on `event_ts` and never mention a partition.

   > **On open-source / On real CDP:** hidden partitioning is an Iceberg
   > differentiator the CDE exam highlights — no more `WHERE dt='...'` boilerplate.

2. **Seed it** from your curated table (Lab 1):

   ```sql
   INSERT INTO demo.de.events_curated
   SELECT id, kind, region, event_ts FROM demo.de.events_clean;
   ```

3. **Inspect the partitions** via metadata:

   ```sql
   SELECT partition, record_count, file_count
   FROM demo.de.events_curated.partitions;
   ```

4. **Build a staging batch** with both *updates* and *new* rows:

   ```sql
   CREATE TABLE demo.de.events_updates (
     id BIGINT, kind STRING, region STRING, event_ts TIMESTAMP
   ) USING iceberg;

   INSERT INTO demo.de.events_updates VALUES
     (1, 'click',  'EU',   TIMESTAMP '2026-06-01 09:00:00'),  -- existing id: update
     (99,'signup', 'APAC', TIMESTAMP '2026-06-02 08:00:00');  -- new id: insert
   ```

5. **Upsert with `MERGE INTO`** — the incremental-load workhorse:

   ```sql
   MERGE INTO demo.de.events_curated t
   USING demo.de.events_updates s
   ON t.id = s.id
   WHEN MATCHED THEN UPDATE SET *
   WHEN NOT MATCHED THEN INSERT *;
   ```

6. **Verify** the merge landed (id 99 inserted, id 1 updated, no duplicates):

   ```sql
   SELECT id, kind, region FROM demo.de.events_curated ORDER BY id;
   SELECT count(*) AS rows FROM demo.de.events_curated;
   ```

   > **On real CDP:** `MERGE INTO` on Iceberg is the standard CDE upsert pattern;
   > the same statement runs against an SDX-governed table.

## Check yourself

- [ ] `events_curated.partitions` shows one partition per event day (step 3).
- [ ] After the merge, `id = 99` exists and there's exactly one `id = 1` (step 6).

## Going further

- Try a `bucket(4, region)` partition spec on a new table and compare layouts.
- Use `CALL demo.system.rewrite_data_files` (Lab 2) to compact within partitions.
- You've completed the Data Engineer track: ingest → curate → maintain →
  orchestrate → incrementally load, all on one governed Iceberg table.
