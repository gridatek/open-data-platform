# viz — Superset

Data Visualization: Apache Superset, reading the **same governed Iceberg tables**
through Trino. This is the platform thesis made visible — a BI engine is just
another consumer of the shared data layer.

```
viz/
├── superset/Dockerfile           # apache/superset + Trino dialect + psycopg2 (→ GHCR)
├── superset/superset_config.py   # Postgres metadata, CSRF on
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
Because CSRF is on, the script first fetches a CSRF token and sends it (with the
session cookie + a `Referer`) on the state-changing POSTs. CI runs this in
`.github/workflows/services-ci.yml`.

Metadata lives in a `superset-db` Postgres (the `dbs`, dashboards, etc. survive a
`superset` container restart). The Postgres + Trino drivers are baked into the
image, so there's no cold-start `pip install`.

## ⚠️ Rough edges

- Still **single-process**: a real deployment adds Redis + a Celery worker for
  async SQL Lab and caching. The metadata store is already Postgres and CSRF is on.
