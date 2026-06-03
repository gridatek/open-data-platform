# 01 Data Engineer — Lab 3: Orchestrate with Airflow

**Time:** ~25 min · **Prereqs:** `make services` (Airflow up), `cd quickstart`

## Goal

Move from running jobs by hand to **orchestrating** them. You'll find the example
DAG, understand its `extract → load → verify` shape, trigger a run, and watch it
in the Airflow UI — the scheduling skills the Data Engineer exam tests.

Airflow UI: http://localhost:8082 (single-process `standalone`; it prints the
admin password on first boot, default `admin`).

## Steps

1. **List the DAGs** — confirm the platform's example is loaded:

   ```bash
   docker compose exec airflow airflow dags list | grep lakehouse_smoke
   ```

2. **Read the DAG.** It lives at
   `platform/engineering/airflow/dags/lakehouse_smoke.py`:

   ```
   extract  >>  load  >>  verify
   ```

   Three `PythonOperator`s wired in sequence, `schedule=None` (manual),
   `catchup=False`. This is the canonical pipeline skeleton.

   > **On open-source:** plain Airflow DAG, no providers required.
   > **On real CDP:** CDE ships managed Airflow; the DAG authoring is identical.

3. **Trigger a run** from the CLI:

   ```bash
   docker compose exec airflow airflow dags trigger lakehouse_smoke
   ```

   …or from the UI: open `lakehouse_smoke` → toggle it **on** → ▶ **Trigger DAG**.

4. **Watch it.** In the UI, open the run's **Grid** view — `extract`, `load`,
   `verify` should go green in order. From the CLI:

   ```bash
   docker compose exec airflow airflow dags list-runs -d lakehouse_smoke
   ```

5. **Read a task log** (the tasks print what they *would* do):

   ```bash
   docker compose exec airflow airflow tasks test lakehouse_smoke load 2026-06-01
   ```

   > **On real CDP:** triggering, monitoring grid/graph views, and reading task
   > logs are all tested CDE workflow skills.

## From illustration to real work

The example tasks log their intent rather than doing the job. To make them real,
add the providers to the Airflow image and swap the operators:

- `extract` → a sensor or extract task
- `load` → `SparkSubmitOperator` running `seed_lakehouse.py` (or your Lab 1 job)
- `verify` → `TrinoOperator` asserting `SELECT count(*) FROM iceberg.smoke.events`

(That needs `apache-airflow-providers-apache-spark` / `-trino` — noted as the
next step in `platform/engineering/README.md`.)

## Check yourself

- [ ] `lakehouse_smoke` appears in `dags list` (step 1).
- [ ] A triggered run shows all three tasks succeeded (step 4).

## Going further

- Give the DAG a real schedule (`schedule="@daily"`) and observe `catchup`.
- Next: [Lab 4 — partitioning & upserts](lab-04-partitioning-upserts.md).
