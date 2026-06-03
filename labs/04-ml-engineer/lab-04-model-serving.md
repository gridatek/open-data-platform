# 04 ML Engineer — Lab 4: Serve a model

**Time:** ~25 min · **Prereqs:** Lab 3 done (a registered `events-classifier`
in `Staging`), `cd quickstart`

## Goal

Close the loop: take the registered model and serve predictions over HTTP, then
see how the same model scores data in batch. This is the inference half of the ML
lifecycle.

We serve *inside* the `spark` container (the model's `sklearn` env is there); the
endpoint isn't host-mapped, so we call it from within the container.

## Steps

1. **Start a serving endpoint** from the registry (background, port 1234):

   ```bash
   docker compose exec -d spark bash -lc \
     "MLFLOW_TRACKING_URI=http://mlflow:5000 mlflow models serve \
        -m 'models:/events-classifier/Staging' \
        -h 0.0.0.0 -p 1234 --env-manager local"
   ```

   Give it ~20 s to load the model from the registry (artifacts stream from MinIO
   via the tracking server).

   > **On open-source:** `mlflow models serve` stands up a REST scorer from a
   > registered model — no packaging step.
   > **On real CDP:** Cloudera AI model *serving* deploys the registered model
   > behind an endpoint; same MLflow model under the hood.

2. **Score a request** (6 features, matching training):

   ```bash
   docker compose exec spark curl -s -X POST http://localhost:1234/invocations \
     -H 'Content-Type: application/json' \
     -d '{"inputs": [[0.1, -1.2, 0.4, 2.0, -0.3, 1.1]]}'
   ```

   You get back a prediction (`{"predictions": [0]}` or `[1]`).

   > **On real CDP:** calling a served model's REST endpoint for online inference
   > is a tested ML-engineer objective.

3. **Stop the endpoint** when done:

   ```bash
   docker compose exec spark pkill -f "mlflow models serve" || true
   ```

## Batch inference (the other half)

Online serving is one mode; scoring a whole table is the other. MLflow loads the
same registered model as a Spark UDF:

```bash
docker compose exec -T spark python - <<'PY'
import mlflow
from pyspark.sql import SparkSession, functions as F
from sklearn.datasets import make_classification
import pandas as pd

spark = SparkSession.builder.getOrCreate()
mlflow.set_tracking_uri("http://mlflow:5000")

# a small feature frame (use real lakehouse features in practice)
X, _ = make_classification(n_samples=5, n_features=6, random_state=7)
cols = [f"f{i}" for i in range(6)]
sdf = spark.createDataFrame(pd.DataFrame(X, columns=cols))

predict = mlflow.pyfunc.spark_udf(spark, "models:/events-classifier/Staging")
sdf.withColumn("prediction", predict(*[F.col(c) for c in cols])).show()
PY
```

> **On real CDP:** batch scoring a governed Iceberg table with a registered model
> is the bridge back to the lakehouse — predictions can be written straight back
> as a new Iceberg table for analysts to consume.

## Check yourself

- [ ] The `/invocations` call returns a prediction (step 2).
- [ ] The batch UDF adds a `prediction` column (batch section).

## Going further

- Write predictions back: `...write.saveAsTable("demo.de.scored")` and query them
  from Trino — the full circle, model output as governed data.
- You've completed the ML Engineer track *and* the curriculum: every track now
  works the same governed lakehouse with a different tool, which is the whole
  point of the platform.
