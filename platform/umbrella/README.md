# umbrella — the Open Data Platform Helm chart

Phase 5 packaging: one chart that deploys the platform onto Kubernetes
(kind/minikube/any cluster). This is the K8s counterpart to the docker-compose
laptop subset under `quickstart/`.

## Status — scaffold

Dependencies with **official upstream charts** are wired and version-pinned:

| Service  | Chart    | Version | Repo                              |
|----------|----------|---------|-----------------------------------|
| MinIO    | minio    | 5.4.0   | https://charts.min.io/            |
| Trino    | trino    | 1.42.2  | https://trinodb.github.io/charts  |
| Superset | superset | 0.15.5  | https://apache.github.io/superset |
| Airflow  | airflow  | 1.21.0  | https://airflow.apache.org        |

The **SDX layer** (Iceberg REST catalog, Ranger, Atlas) and the **streaming/ML**
services (Kafka, NiFi, MLflow) have no upstream chart — they need local subcharts
under `charts/`, ported from the docker-compose definitions. That porting is the
remaining Phase 5 work; `values.yaml` lists them as `enabled: false` stubs.

## Use

```bash
helm repo add minio https://charts.min.io/
helm repo add trino https://trinodb.github.io/charts
helm repo add superset https://apache.github.io/superset
helm repo add apache-airflow https://airflow.apache.org
helm repo update

helm dependency build platform/umbrella
helm install odp platform/umbrella -n odp --create-namespace
```

Toggle services with `--set <name>.enabled=true|false`. CI runs
`helm dependency build` + `helm lint` in `.github/workflows/helm-ci.yml`.

> ⚠️ Passwords in `values.yaml` are placeholders. Override with `--set` or a
> secret before using anywhere real.
