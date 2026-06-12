# Hive — the LEGACY table format (learning only) ⚠️

> **This is the old world, kept on purpose.**
> The modern lakehouse in this repo is **Iceberg** (one shared REST catalog,
> read by both Trino and Spark). **Hive + the Hive Metastore (HMS) is legacy** —
> in CDP it's the format you *migrate away from*, not what you build new
> workloads on. This lab exists so you can *see* the old path and practise the
> **Hive → Iceberg migration**, which is a real interview topic. Don't reach for
> the `hive` catalog for anything new — use `iceberg`.

## What you get

| Piece | Role |
|-------|------|
| `hive-metastore` (`apache/hive:4.0.0`) | The classic **Hive Metastore** on Thrift `:9083`, with an embedded Derby DB. Metadata only — and ephemeral (no volume), fitting for a throwaway demo. |
| Trino catalog `hive` | `platform/warehouse/hive/catalog/hive.properties` — Trino's Hive connector, pointed at HMS for metadata and at **MinIO/S3** (the same bucket as Iceberg) for data. The overlay mounts `catalog/` as Trino's whole catalog dir, so it also carries a copy of `iceberg.properties` (the migration target). |

Why HMS *and* Iceberg's REST catalog exist side by side: HMS is the pre-Iceberg
metadata service. Iceberg replaced it here with the REST catalog
(`iceberg-rest`). Running both lets you compare them and move data across.

## Run it

It's an optional overlay on the base lakehouse — **off by default**, and lean
(only MinIO + Trino + HMS come up, so it fits the laptop):

```bash
make hive          # starts minio, minio-init, trino, hive-metastore
```

Then run the proof — it creates a legacy Hive table, queries it from Trino, and
**migrates it into Iceberg**, asserting the row counts and totals match:

```bash
./platform/warehouse/hive/hive-legacy.sh
```

Tear down with `make down` (wipes volumes).

## The migration, by hand

```sql
-- legacy: a Hive table, metadata in HMS, data on S3
CREATE SCHEMA hive.legacy WITH (location = 's3a://warehouse/hive/legacy');
CREATE TABLE hive.legacy.sales (id bigint, region varchar, amount double)
  WITH (format = 'PARQUET', external_location = 's3a://warehouse/hive/legacy/sales');

-- modern: lift it into Iceberg (snapshots, time travel, REST catalog)
CREATE TABLE iceberg.migrated.sales AS SELECT * FROM hive.legacy.sales;
```

In a real CDP cluster you'd often do an in-place `ALTER TABLE ... CONVERT TO
ICEBERG` / snapshot migration instead of a copy, but the CTAS above is the
clearest way to see the two formats next to each other.

See the modern path in `quickstart/trino/etc/catalog/iceberg.properties` and the
analytics lab in `platform/warehouse/run-analytics-sql.sh`.
