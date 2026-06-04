# MLflow with boto3 baked in (for the MinIO/S3 artifact store), so it's present
# at start instead of `pip install`ed on every boot.
FROM ghcr.io/mlflow/mlflow:v2.17.2

RUN pip install --no-cache-dir boto3
