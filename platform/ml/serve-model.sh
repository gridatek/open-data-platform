#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# MLflow model serving proof. Log a self-contained pyfunc model, serve it with
# `mlflow models serve`, and POST an inference request to /invocations.
#
# Run from quickstart/ with MLflow up. Everything runs inside the mlflow
# container (it has mlflow + pandas + requests; the pyfunc model needs no extra
# framework, so --env-manager local serves without building a venv).
# ───────────────────────────────────────────────────────────────
set -euo pipefail

DC="docker compose -f docker-compose.yml -f docker-compose.services.yml"

${DC} exec -T mlflow bash -s <<'INNER'
set -euo pipefail
export MLFLOW_TRACKING_URI=http://localhost:5000

cat > /tmp/log_model.py <<'PY'
import mlflow
import pandas as pd
from mlflow.pyfunc import PythonModel


class AddOne(PythonModel):
    """Trivial model: predicts x + 1 (no framework, so serving needs no venv)."""

    def predict(self, context, model_input):
        return (model_input["x"] + 1).tolist()


mlflow.set_tracking_uri("http://localhost:5000")
mlflow.set_experiment("odp-serving")
with mlflow.start_run():
    mlflow.pyfunc.log_model(
        artifact_path="model",
        python_model=AddOne(),
        registered_model_name="odp-serve-model",
        input_example=pd.DataFrame({"x": [1]}),
    )
print("[serve] logged + registered odp-serve-model")
PY

python /tmp/log_model.py

echo "[serve] starting 'mlflow models serve' on :5001 ..."
mlflow models serve -m "models:/odp-serve-model/1" -p 5001 --host 0.0.0.0 \
  --env-manager local >/tmp/serve.log 2>&1 &
SPID=$!
trap 'kill ${SPID} 2>/dev/null || true' EXIT

# The mlflow image has no curl; use requests (an mlflow dependency).
python - <<'PY'
import time, sys, requests
for _ in range(40):
    try:
        if requests.get("http://localhost:5001/ping", timeout=2).ok:
            break
    except Exception:
        pass
    time.sleep(3)
else:
    print("[serve] server never came up", file=sys.stderr); sys.exit(1)

resp = requests.post(
    "http://localhost:5001/invocations",
    json={"dataframe_split": {"columns": ["x"], "data": [[41]]}},
    timeout=15,
)
print("[serve] /invocations response =", resp.text)
assert "42" in resp.text, resp.text
print("[serve] OK — model served an inference (41 -> 42) via mlflow models serve.")
PY
INNER
