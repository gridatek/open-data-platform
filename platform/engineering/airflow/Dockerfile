# Airflow with the Trino provider baked in, so the lakehouse DAG can write/read
# through Trino at start — no `_PIP_ADDITIONAL_REQUIREMENTS` pip-on-boot.
# Pinned via the matching Airflow constraints for a reproducible build.
#
# AIRFLOW_VERSION is a build-arg so one Dockerfile serves both paths:
#   • compose  → 2.10.4 (the laptop subset's `airflow standalone`)  → tag :latest
#   • umbrella → 3.2.0  (the Helm chart's appVersion)               → tag :3.2.0
ARG AIRFLOW_VERSION=2.10.4
FROM apache/airflow:${AIRFLOW_VERSION}

# Re-declare after FROM so it's usable in RUN; PY is the constraints' python tag.
ARG AIRFLOW_VERSION
ARG CONSTRAINTS_PY=3.12
RUN pip install --no-cache-dir \
    "apache-airflow-providers-trino" \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${CONSTRAINTS_PY}.txt"
