# engineering — Spark + Airflow (≈ CDE)

Data Engineering: **Spark** for transforms (the Phase 0 seed job already writes
Iceberg) and **Airflow** for orchestration.

```
engineering/
├── airflow/Dockerfile               # apache/airflow + the Trino provider (→ GHCR)
└── airflow/dags/lakehouse_smoke.py  # DAG: extract -> load (Trino) -> verify (Trino)
```

## Run (Phase 3 overlay)

From `quickstart/`:

```bash
docker compose -f docker-compose.yml -f docker-compose.services.yml up -d airflow
```

Airflow UI: http://localhost:8082 (single-process `standalone`; it prints the
admin password on first boot, default `admin`). The `lakehouse_smoke` DAG runs
**real operators**: `extract` → `load` (a `SQLExecuteQueryOperator` that writes
the demo rows into `iceberg.smoke.events` through Trino) → `verify` (a
`SQLValueCheckOperator` asserting the count is 4). Both use the `trino_default`
connection (`AIRFLOW_CONN_TRINO_DEFAULT`) and the `apache-airflow-providers-trino`
provider baked into the image. `services-ci` brings up Trino + Airflow and runs
the DAG end-to-end (`airflow dags test`), not just a parse check.

To run it yourself:

```bash
docker compose -f docker-compose.yml -f docker-compose.services.yml up -d --build trino airflow
docker compose exec airflow airflow dags test lakehouse_smoke 2026-06-01
```

## ⚠️ Rough edges

- `load` writes through **Trino** (Trino writes Iceberg natively) rather than
  submitting the Spark `seed_lakehouse.py`, so we don't have to embed a full
  Spark runtime in the Airflow image. The production variant submits the Spark
  job to a real cluster via `SparkKubernetesOperator` / `SparkSubmitOperator`.
- `standalone` runs the webserver + scheduler in one container — laptop-only.
  But its metadata now lives in a dedicated `airflow-db` Postgres with the
  `LocalExecutor` (so DAG runs, connections and history survive a restart and
  tasks run concurrently). A real deployment splits the components and swaps in
  the Celery/Kubernetes executor.
