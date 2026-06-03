# 00 Generalist — Lab 1: The SDX model — one table, many engines

**Time:** ~25 min · **Prereqs:** platform up (`make all`), `cd quickstart`

## Goal

Prove the platform's central claim to yourself: a single governed Iceberg table,
written by one engine, is read by several others — and one governance policy
applies to all of them. By the end you'll have written with **Spark**, read with
**Trino** and **Superset**, masked a column with **Ranger**, and seen lineage in
**Atlas** — all over the *same* table.

## Steps

1. **Write the table from Spark.**

   ```bash
   docker compose exec spark spark-submit /home/iceberg/jobs/seed_lakehouse.py
   ```

   > **On open-source:** Spark writes an Apache Iceberg table through the shared
   > REST catalog; the data lands in MinIO (S3).
   > **On real CDP:** this is a **CDE** Spark job writing an Iceberg table into
   > the SDX-governed storage — same Iceberg, same catalog concept.

2. **Read it from Trino** (a *different* engine, same catalog):

   ```bash
   docker compose exec trino trino --execute "SELECT * FROM iceberg.smoke.events ORDER BY id"
   ```

   > **On open-source:** Trino resolves `iceberg.smoke.events` via the REST
   > catalog and reads the very files Spark wrote — no copy, no export.
   > **On real CDP:** the same query runs in **CDW** (Hive/Impala). The engine
   > changed; the governed table did not. *This is SDX.*

3. **Govern it — mask a column with Ranger.** Bring up governance if you haven't,
   then load the policies:

   ```bash
   ../platform/governance/load-policies.sh
   sleep 30   # let Trino's Ranger plugin poll the policy
   docker compose exec trino trino --user analyst \
     --execute "SELECT id, kind FROM iceberg.smoke.events ORDER BY id"
   ```

   The `kind` column comes back masked for `analyst`, clear for `admin`.

   > **On open-source:** one Ranger masking policy is enforced *inside* Trino.
   > **On real CDP:** the identical Ranger policy masks the column in CDW for the
   > same user — the policy lives in SDX, not in any one engine. (Generalist exam:
   > "a single security/policy model across services".)

4. **Visualize it from Superset** (a third engine):

   ```bash
   docker compose -f docker-compose.yml -f docker-compose.services.yml up -d superset
   ../platform/viz/register-trino.sh
   ```

   Open http://localhost:8088 → SQL Lab → query `iceberg.smoke.events`.

   > **On open-source:** Superset reaches the table *through Trino* — yet another
   > consumer of the one governed table.
   > **On real CDP:** Cloudera Data Visualization over CDW, same governed data.

5. **See lineage in Atlas.**

   ```bash
   ../platform/governance/atlas/register-lineage.sh
   ```

   Open http://localhost:21000 → search `iceberg.smoke.events` → Lineage tab.

   > **On open-source:** Atlas shows `events_source → seed_lakehouse → events`.
   > **On real CDP:** Atlas lineage is part of SDX, populated automatically by the
   > engines as jobs run.

## Check yourself

- [ ] Trino returns the 4 rows Spark wrote (step 2).
- [ ] `analyst` sees `kind` masked while `admin` sees it clear (step 3).
- [ ] Superset's SQL Lab returns rows from the same table (step 4).
- [ ] Atlas shows an upstream lineage edge into the table (step 5).

## Going further

- Flip the masking policy off and on **from the console UI**
  (http://localhost:4200, the Enable/Disable button) and re-run step 3's query —
  watch the masking change without touching any engine. That's the control plane.
- Continue to the **02 Data Analyst** track to go deep on Trino SQL, Superset
  dashboards, and Ranger column masking.
