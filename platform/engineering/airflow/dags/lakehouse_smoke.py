"""lakehouse_smoke — a Data Engineering pipeline on the platform.

    extract  ->  load (Trino write)  ->  verify (Trino count)

The pipeline writes through the shared Iceberg REST catalog and reads it straight
back, so it exercises the same governed table (`iceberg.smoke.events`) that
Superset, Spark and the masking proof use.

Operators are real:
  • `load`   — SQLExecuteQueryOperator runs Iceberg DDL/DML through Trino. Trino
    writes to Iceberg natively, so we don't have to embed a full Spark runtime in
    the Airflow image. (The production variant submits `seed_lakehouse.py` to a
    real Spark cluster via SparkKubernetesOperator / SparkSubmitOperator.)
  • `verify` — SQLValueCheckOperator asserts the row count is exactly 4.

Both use the `trino_default` connection (provided via AIRFLOW_CONN_TRINO_DEFAULT
= trino://admin@trino:8080/iceberg), and the apache-airflow-providers-trino
provider baked into the image.
"""
from __future__ import annotations

import pendulum
from airflow.models.dag import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.common.sql.operators.sql import (
    SQLExecuteQueryOperator,
    SQLValueCheckOperator,
)

TABLE = "iceberg.smoke.events"

# (id, kind, ts) — small, deterministic, four rows; mirrors seed_lakehouse.py.
SEED_SQL = [
    "CREATE SCHEMA IF NOT EXISTS iceberg.smoke",
    f"""
    CREATE TABLE IF NOT EXISTS {TABLE} (
        id   BIGINT,
        kind VARCHAR,
        ts   TIMESTAMP(6)
    )
    """,
    # Idempotent reseed: start from empty so the row count is stable.
    f"DELETE FROM {TABLE}",
    f"""
    INSERT INTO {TABLE} (id, kind, ts) VALUES
        (1, 'click',    TIMESTAMP '2026-06-01 10:00:00'),
        (2, 'view',     TIMESTAMP '2026-06-01 10:01:30'),
        (3, 'click',    TIMESTAMP '2026-06-01 10:02:15'),
        (4, 'purchase', TIMESTAMP '2026-06-01 10:05:00')
    """,
]

with DAG(
    dag_id="lakehouse_smoke",
    schedule=None,
    start_date=pendulum.datetime(2026, 1, 1, tz="UTC"),
    catchup=False,
    tags=["odp", "phase3", "engineering"],
) as dag:

    def _extract() -> str:
        # Stand-in for pulling a raw source; the demo rows are baked into `load`.
        print("extract: resolved the raw events source")
        return "events_source"

    extract = PythonOperator(task_id="extract", python_callable=_extract)

    load = SQLExecuteQueryOperator(
        task_id="load",
        conn_id="trino_default",
        sql=SEED_SQL,
        autocommit=True,
    )

    verify = SQLValueCheckOperator(
        task_id="verify",
        conn_id="trino_default",
        sql=f"SELECT count(*) FROM {TABLE}",
        pass_value=4,
    )

    extract >> load >> verify
