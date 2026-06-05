# engineering — Spark + Airflow (≈ CDE)

Data Engineering: **Spark** for transforms (the Phase 0 seed job already writes
Iceberg) and **Airflow** for orchestration.

```
engineering/
└── airflow/dags/lakehouse_smoke.py   # example DAG: extract -> load -> verify
```

## Run (Phase 3 overlay)

From `quickstart/`:

```bash
docker compose -f docker-compose.yml -f docker-compose.services.yml up -d airflow
```

Airflow UI: http://localhost:8082 (single-process `standalone`; it prints the
admin password on first boot, default `admin`). The `lakehouse_smoke` DAG shows
the pipeline shape; CI asserts it parses in `.github/workflows/services-ci.yml`.

## ⚠️ Rough edges

- The DAG tasks are **illustrative** (stdlib `PythonOperator`s that log intent).
  Wiring real operators — `SparkSubmitOperator` for `seed_lakehouse.py`,
  `TrinoOperator` for the row-count check — needs the
  `apache-airflow-providers-apache-spark` / `-trino` providers added to the
  Airflow image. That's the next step.
- `standalone` runs the webserver + scheduler in one container — laptop-only.
  But its metadata now lives in a dedicated `airflow-db` Postgres with the
  `LocalExecutor` (so DAG runs, connections and history survive a restart and
  tasks run concurrently). A real deployment splits the components and swaps in
  the Celery/Kubernetes executor.
