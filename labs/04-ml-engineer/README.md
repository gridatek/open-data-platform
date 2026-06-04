# 04 ML Engineer → Cloudera ML Engineer (CDP-60xx)

The ML engineer's loop on the governed lakehouse: prep features in a **notebook**,
track experiments with **MLflow**, register a **model** (artifacts in MinIO), and
**serve** it for predictions — all reading the same Iceberg data the analysts and
engineers use.

Bring up the lakehouse + MLflow:

```bash
make core           # Spark (with Jupyter) + Trino + catalog + MinIO
make services       # adds MLflow (and the rest)
make seed           # demo iceberg.smoke.events
cd quickstart
```

Workbenches: Jupyter http://localhost:8888 · MLflow http://localhost:5000.

For the **multi-user** notebook hub (the closer CML analog — users log in and
each gets their own JupyterLab), bring up JupyterHub:

```bash
make jupyterhub     # JupyterHub http://localhost:8000 (any user / password "jupyter")
```

The labs below use the single Spark Jupyter on :8888 for simplicity; the same
PySpark code runs in a JupyterHub-spawned notebook.

## Labs

| # | Lab | Cert objective it maps to |
|---|-----|---------------------------|
| 01 | [Notebooks on the lakehouse](lab-01-notebooks.md) | Notebook sessions reading governed data |
| 02 | [Experiment tracking with MLflow](lab-02-experiment-tracking.md) | Log params/metrics, compare runs |
| 03 | [Model registry & artifacts](lab-03-model-registry.md) | Register models, manage versions/stages |
| 04 | [Serve a model](lab-04-model-serving.md) | Online + batch inference |

> **On real CDP:** this is **Cloudera AI / CML** — notebook sessions, MLflow
> experiment tracking, the model registry, and model serving. The tools here are
> the same open-source MLflow + notebooks CML is built on, so the workflow
> transfers directly.

## A note on dependencies

The `spark-iceberg` image ships PySpark + Jupyter but not the ML libraries, so the
labs `pip install mlflow scikit-learn` into the running container. That's a laptop
convenience; a real image would bake them in.
