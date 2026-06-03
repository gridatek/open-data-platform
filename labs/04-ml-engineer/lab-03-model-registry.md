# 04 ML Engineer — Lab 3: Model registry & artifacts

**Time:** ~25 min · **Prereqs:** Lab 2 done (mlflow + sklearn installed),
`cd quickstart`

## Goal

Promote a trained model from "a run" to a **registered, versioned model** whose
artifacts live in MinIO — the handoff point between training and serving.

## Steps

1. **Train and log a model to the registry** in one shot:

   ```bash
   docker compose exec -T spark python - <<'PY'
   import mlflow, mlflow.sklearn
   from sklearn.datasets import make_classification
   from sklearn.linear_model import LogisticRegression

   mlflow.set_tracking_uri("http://mlflow:5000")
   mlflow.set_experiment("events-classifier")

   X, y = make_classification(n_samples=500, n_features=6, random_state=42)
   with mlflow.start_run():
       model = LogisticRegression(max_iter=1000).fit(X, y)
       mlflow.sklearn.log_model(
           model, artifact_path="model",
           registered_model_name="events-classifier")
       print("model logged and registered")
   PY
   ```

   > **On open-source:** `log_model(..., registered_model_name=...)` uploads the
   > model artifact *and* creates a registered version.
   > **On real CDP:** Cloudera AI's model registry is this same MLflow registry.

2. **See the artifact land in MinIO.** The tracking server stores artifacts in
   `s3://mlflow` (it runs with `--serve-artifacts`). Browse the **MinIO console**
   at http://localhost:9001 (admin / password) → bucket `mlflow` → you'll see the
   model files under the experiment/run path.

   > **On open-source / On real CDP:** model artifacts in object storage, next to
   > the lakehouse data — one storage layer for data *and* models.

3. **Inspect the registered model.** MLflow UI http://localhost:5000 → **Models**
   → `events-classifier` → version 1.

4. **Promote a version** to Staging (programmatically):

   ```bash
   docker compose exec -T spark python - <<'PY'
   from mlflow import MlflowClient
   c = MlflowClient("http://mlflow:5000")
   c.transition_model_version_stage(
       name="events-classifier", version=1, stage="Staging")
   mv = c.get_model_version("events-classifier", 1)
   print("version", mv.version, "stage:", mv.current_stage)
   PY
   ```

   …or use the **Stage** dropdown on the model-version page in the UI.

   > **On real CDP:** stage transitions (Staging → Production) gate what gets
   > served — a tested ML lifecycle objective. (Newer MLflow also offers model
   > *aliases* as an alternative to stages.)

## Check yourself

- [ ] `events-classifier` version 1 exists in the Models registry (step 3).
- [ ] Model files are present in the MinIO `mlflow` bucket (step 2).
- [ ] Version 1's stage reads `Staging` after promotion (step 4).

## Going further

- Log a second run with different params and register version 2; compare.
- Next: [Lab 4 — serve a model](lab-04-model-serving.md).
