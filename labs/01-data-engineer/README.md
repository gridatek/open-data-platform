# 01 Data Engineer → CDP Data Engineer (CDP-3002)

The engineer's view of the lakehouse: **ingest and transform with Spark**, then
**build and maintain Iceberg tables** (schema evolution, snapshots, time travel,
compaction), and **orchestrate** the whole thing with **Airflow**.

Everything here uses Spark's catalog name `demo` (the `spark-iceberg` image's
built-in REST catalog). The *same* tables are visible to Trino as `iceberg` —
write with one engine, read with another, one governed catalog.

## Labs

| # | Lab | Cert objective it maps to |
|---|-----|---------------------------|
| 01 | [Ingest & transform with Spark](lab-01-spark-transform.md) | Build a curated table from raw with Spark SQL |
| 02 | [Maintain Iceberg tables](lab-02-iceberg-maintenance.md) | Schema evolution, snapshots, time travel, compaction |
| 03 | [Orchestrate with Airflow](lab-03-airflow-orchestration.md) | DAGs: schedule, trigger, monitor a pipeline |
| 04 | [Partitioning & upserts](lab-04-partitioning-upserts.md) | Hidden partitioning + `MERGE INTO` incremental loads |

## Prerequisites

```bash
make core           # the lakehouse (Spark + Trino + catalog + MinIO)
make services       # adds Airflow (for Lab 3)
cd quickstart       # labs run docker compose from here
```

Open a Spark SQL shell for Labs 1, 2, 4:

```bash
docker compose exec spark spark-sql
```

> **On real CDP:** these are **CDE** (Cloudera Data Engineering) tasks — Spark
> jobs and Airflow DAGs over Iceberg tables in SDX-governed storage. The OSS
> tools and the SQL/DDL are the same; only the control plane differs.
