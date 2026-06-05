# ml — JupyterHub + MLflow (≈ CML)

Machine Learning: **MLflow** for experiment tracking + model registry, and
**JupyterHub** for multi-user notebooks ([`jupyterhub/`](jupyterhub/)). (The
Phase 0 `spark-iceberg` image also ships a single Jupyter on :8888.)

```
ml/
├── log-run.sh      # log a run to MLflow via REST and read it back (the proof)
├── mlflow/         # MLflow image: boto3 baked in (Dockerfile → GHCR)
└── jupyterhub/     # multi-user notebook hub (Dockerfile + config + smoke)
```

## Run (Phase 3 overlay)

From `quickstart/`:

```bash
docker compose -f docker-compose.yml -f docker-compose.services.yml up -d mlflow
../platform/ml/log-run.sh
```

MLflow UI: http://localhost:5000. The server keeps metadata in **Postgres**
(`mlflow-db`) and stores artifacts in **MinIO** (`s3://mlflow`) via
`--serve-artifacts`, so ML artifacts live in the same object store as the
lakehouse. The script creates an experiment, logs a param + metric, finishes the
run, and asserts it reads back. CI runs this in `.github/workflows/services-ci.yml`.

## ⚠️ Rough edges

- `boto3` + `psycopg2` are **baked into a custom image** (`mlflow/Dockerfile`,
  published to GHCR) — no cold-start `pip install`.
- Metadata is in **Postgres** and artifacts in **MinIO** — both production-shaped.
  (The umbrella `mlflow` subchart ships its own Postgres, like `ranger`.)
- The proof logs metadata via REST; it doesn't yet upload an artifact through
  the MinIO path. Logging a model from a notebook (`mlflow.log_artifact`) is the
  next step.
