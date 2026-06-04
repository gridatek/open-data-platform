# umbrella — the Open Data Platform Helm chart

Phase 5 packaging: one chart that deploys the platform onto Kubernetes
(kind/minikube/any cluster). This is the K8s counterpart to the docker-compose
laptop subset under `quickstart/`.

## Status — in progress

Dependencies with **official upstream charts** are wired and version-pinned:

| Service  | Chart    | Version | Repo                              |
|----------|----------|---------|-----------------------------------|
| MinIO    | minio    | 5.4.0   | https://charts.min.io/            |
| Trino    | trino    | 1.42.2  | https://trinodb.github.io/charts  |
| Superset | superset | 0.15.5  | https://apache.github.io/superset |
| Airflow  | airflow  | 1.21.0  | https://airflow.apache.org        |

The **SDX layer** (Iceberg REST catalog, Ranger, Atlas) and the **streaming/ML**
services (Kafka, NiFi, MLflow) have no upstream chart, so they're being ported to
local subcharts under `charts/`:

| Local subchart  | Status   | Notes |
|-----------------|----------|-------|
| `iceberg-rest`  | ✅ done   | The SDX catalog spine. Trino's `iceberg` catalog is wired to it via `additionalCatalogs`; MinIO is pinned to a stable Service name so the catalog resolves it. |
| `atlas`         | ✅ done   | SDX lineage. Single container (embedded HBase + Solr), pinned by digest; `startupProbe` tolerates the slow boot. Heavy (~3Gi) — `--set atlas.enabled=false` to skip. |
| `ranger`        | ✅ done¹  | Policy server + UI **and** its Postgres metadata store (admin Deployment + db Deployment/Service/PVC). Stable Service names `ranger-admin` / `ranger-db`. |
| `kafka`         | ✅ done   | Single-node KRaft broker; advertised listener uses the stable `kafka` Service name. Default off. |
| `nifi`          | ✅ done   | Flow authoring, plain HTTP/anonymous; `startupProbe` on `/nifi`. Default off. |
| `mlflow`        | ✅ done   | Tracking server; SQLite metadata, artifacts in the MinIO `mlflow` bucket. Default off. |

¹ Apache publishes no Ranger *admin* image, so it's built from
`platform/governance/ranger`. **Build and load it before enabling** the
subchart — that's why `ranger.enabled` defaults to `false`:

```bash
docker build -t odp/ranger-admin:2.4.0 platform/governance/ranger
kind load docker-image odp/ranger-admin:2.4.0      # or push to your registry
helm install odp platform/umbrella --set ranger.enabled=true
```

MinIO + the Iceberg REST catalog + Trino + Atlas (+ Ranger, once its image is
loaded) now render as a governed lakehouse on K8s (`helm template` in CI); the
remaining subcharts are `enabled: false` in `values.yaml` until they're ported.

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
