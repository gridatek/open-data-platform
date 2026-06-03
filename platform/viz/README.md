# viz — Superset

Data Visualization: Apache Superset, reading the **same governed Iceberg tables**
through Trino. This is the platform thesis made visible — a BI engine is just
another consumer of the shared data layer.

```
viz/
├── superset/superset_config.py   # SQLite metadata, CSRF off (laptop subset)
└── register-trino.sh             # add Trino as a Superset DB + run a proof query
```

## Run (Phase 3 overlay)

From `quickstart/`, with the lakehouse up:

```bash
docker compose -f docker-compose.yml -f docker-compose.services.yml up -d superset spark
docker compose exec spark spark-submit /home/iceberg/jobs/seed_lakehouse.py
../platform/viz/register-trino.sh
```

Superset UI: http://localhost:8088 (admin / admin). The script registers the
`trino://admin@trino:8080/iceberg` connection and runs
`SELECT count(*) FROM iceberg.smoke.events` via SQL Lab, asserting it returns 4.
CI runs this in `.github/workflows/services-ci.yml`.

## ⚠️ Rough edges

- The Trino dialect is `pip install`ed at container start (no custom image yet);
  fine for the laptop subset, slow on cold start.
- SQLite metadata + CSRF disabled are **dev-only**. A real deployment uses
  Postgres + Redis + a worker, and keeps CSRF on.
