# 01 Data Engineer — Lab 2: Maintain Iceberg tables

**Time:** ~30 min · **Prereqs:** Lab 1 done (`demo.de.events_clean` exists),
Spark SQL shell open (`docker compose exec spark spark-sql`)

## Goal

The features that make Iceberg a *table format* and not just files: evolve the
schema safely, inspect snapshots, time-travel to a past version, and compact +
expire old data. These are the maintenance tasks a Data Engineer owns.

> **Runnable demos (CI-proven):** schema evolution + time-travel live in
> `quickstart/spark/jobs/iceberg_features.py` (+ `platform/engineering/iceberg-features.sh`);
> compaction + snapshot expiry in `quickstart/spark/jobs/maintain_lakehouse.py`.
> `quickstart-ci` runs both.

## Steps

1. **Evolve the schema** — add a column without rewriting data:

   ```sql
   ALTER TABLE demo.de.events_clean ADD COLUMN source STRING;
   INSERT INTO demo.de.events_clean
     VALUES (7, 'click', 'US', TIMESTAMP '2026-06-01 11:00:00', 'mobile');
   SELECT id, kind, source FROM demo.de.events_clean ORDER BY id;
   ```

   Old rows show `source = NULL`; the new row is populated. No migration needed.

   > **On open-source:** Iceberg schema evolution is metadata-only and safe.
   > **On real CDP:** identical — Iceberg in SDX evolves the same way; a tested
   > CDE objective.

2. **Inspect snapshots** via the metadata tables:

   ```sql
   SELECT snapshot_id, committed_at, operation
   FROM demo.de.events_clean.snapshots
   ORDER BY committed_at;
   ```

   Each `INSERT`/`ALTER` produced a snapshot. Note the **first** `snapshot_id`.

3. **Time-travel** to that first snapshot (replace the id):

   ```sql
   SELECT count(*) FROM demo.de.events_clean VERSION AS OF <first_snapshot_id>;
   -- or by wall-clock:
   -- SELECT count(*) FROM demo.de.events_clean TIMESTAMP AS OF '2026-06-01 09:00:00';
   ```

   You get the row count *as it was then* — reproducible reads and easy rollback.

   > **On real CDP:** time travel / snapshot isolation is a headline Iceberg
   > capability the exam expects you to know.

4. **Compact small files.** Lots of small `INSERT`s make small files; rewrite
   them into fewer, larger ones:

   ```sql
   CALL demo.system.rewrite_data_files(table => 'de.events_clean');
   ```

   Check the file count before/after:

   ```sql
   SELECT count(*) AS data_files FROM demo.de.events_clean.files;
   ```

5. **Expire old snapshots** to reclaim storage (keeps the table's history bounded):

   ```sql
   CALL demo.system.expire_snapshots(
     table => 'de.events_clean',
     older_than => TIMESTAMP '2999-01-01 00:00:00',
     retain_last => 1
   );
   ```

   > **On open-source / On real CDP:** `rewrite_data_files` + `expire_snapshots`
   > are the standard Iceberg maintenance procedures — same calls on CDP.

## Check yourself

- [ ] Old rows have `source = NULL` after the `ADD COLUMN` (step 1).
- [ ] The snapshots table lists multiple snapshots (step 2).
- [ ] Time-travel returns a *smaller* count than the current table (step 3).
- [ ] `data_files` drops after compaction (step 4).

## Going further

- Look at `demo.de.events_clean.history` and `.manifests` metadata tables.
- Next: [Lab 3 — orchestrate with Airflow](lab-03-airflow-orchestration.md).
