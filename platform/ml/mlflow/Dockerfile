# MLflow with boto3 (MinIO/S3 artifact store) and psycopg2 (Postgres backend
# store) baked in, so they're present at start instead of pip-installed on boot.
FROM ghcr.io/mlflow/mlflow:v2.17.2

RUN pip install --no-cache-dir boto3 psycopg2-binary
