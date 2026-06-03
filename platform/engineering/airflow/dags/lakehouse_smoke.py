"""lakehouse_smoke — a minimal Phase 3 orchestration example.

Shows the *shape* of a Data Engineering pipeline on the platform:

    extract  ->  load (Spark seed)  ->  verify (Trino count)

The tasks are intentionally dependency-light (stdlib only) so the DAG parses
without extra Airflow providers. Wiring real operators — SparkSubmitOperator
to run seed_lakehouse.py, TrinoOperator to assert the row count — is the next
step; the providers (apache-airflow-providers-apache-spark / -trino) get added
to the Airflow image then.
"""
from __future__ import annotations

import pendulum
from airflow.models.dag import DAG
from airflow.operators.python import PythonOperator

with DAG(
    dag_id="lakehouse_smoke",
    schedule=None,
    start_date=pendulum.datetime(2026, 1, 1, tz="UTC"),
    catchup=False,
    tags=["odp", "phase3", "engineering"],
) as dag:

    def _extract() -> str:
        print("extract: would pull the raw events source")
        return "events_source"

    def _load() -> None:
        # TODO: SparkSubmitOperator -> /home/iceberg/jobs/seed_lakehouse.py
        print("load: would run the Spark seed into iceberg.smoke.events")

    def _verify() -> None:
        # TODO: TrinoOperator -> SELECT count(*) FROM iceberg.smoke.events
        print("verify: would assert the Trino row count == 4")

    extract = PythonOperator(task_id="extract", python_callable=_extract)
    load = PythonOperator(task_id="load", python_callable=_load)
    verify = PythonOperator(task_id="verify", python_callable=_verify)

    extract >> load >> verify
