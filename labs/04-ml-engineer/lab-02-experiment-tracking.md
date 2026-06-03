# 04 ML Engineer — Lab 2: Experiment tracking with MLflow

**Time:** ~25 min · **Prereqs:** `make services` (MLflow up), `cd quickstart`

## Goal

Stop losing track of what you tried. Log parameters, metrics, and runs to MLflow,
then compare them in the UI — the experiment-tracking discipline the ML exam tests.

We'll run from the `spark` container so MLflow is reachable in-network at
`http://mlflow:5000`.

## Steps

1. **Install the ML libraries** into the container (laptop convenience):

   ```bash
   docker compose exec spark pip install --quiet mlflow scikit-learn
   ```

2. **Train a few models and log each run.** Save this as a here-doc and run it:

   ```bash
   docker compose exec -T spark python - <<'PY'
   import mlflow
   from sklearn.datasets import make_classification
   from sklearn.linear_model import LogisticRegression
   from sklearn.model_selection import train_test_split
   from sklearn.metrics import accuracy_score

   mlflow.set_tracking_uri("http://mlflow:5000")
   mlflow.set_experiment("events-classifier")

   X, y = make_classification(n_samples=500, n_features=6, random_state=42)
   Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.2, random_state=42)

   for C in [0.1, 1.0, 10.0]:
       with mlflow.start_run():
           model = LogisticRegression(C=C, max_iter=1000).fit(Xtr, ytr)
           acc = accuracy_score(yte, model.predict(Xte))
           mlflow.log_param("C", C)
           mlflow.log_metric("accuracy", acc)
           print(f"logged run: C={C} accuracy={acc:.3f}")
   PY
   ```

   > **On open-source:** `mlflow.start_run()` + `log_param`/`log_metric` records
   > each experiment to the tracking server (metadata in SQLite here).
   > **On real CDP:** Cloudera AI's experiment tracking is this same MLflow API —
   > the code is identical.

   > In a notebook (Lab 1)? Paste the same Python into a cell — but set the URI to
   > `http://mlflow:5000` either way (both run inside the `odp` network).

3. **Compare runs in the UI.** Open http://localhost:5000 → experiment
   `events-classifier`. You'll see three runs; select them and **Compare** to plot
   `accuracy` against `C`.

4. **Find the best run** programmatically:

   ```bash
   docker compose exec -T spark python - <<'PY'
   import mlflow
   mlflow.set_tracking_uri("http://mlflow:5000")
   best = mlflow.search_runs(experiment_names=["events-classifier"],
                             order_by=["metrics.accuracy DESC"]).iloc[0]
   print("best C =", best["params.C"], "accuracy =", best["metrics.accuracy"])
   PY
   ```

   > **On real CDP:** comparing runs and selecting a champion model is a core ML
   > workflow objective.

## Check yourself

- [ ] Three runs appear under `events-classifier` in the MLflow UI (step 3).
- [ ] The Compare view plots accuracy vs `C` (step 3).
- [ ] `search_runs` returns the highest-accuracy run (step 4).

## Going further

- Replace the synthetic data with real features from Lab 1 (`is_purchase`).
- Next: [Lab 3 — model registry & artifacts](lab-03-model-registry.md).
