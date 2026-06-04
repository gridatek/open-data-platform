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

The **SDX layer** (Iceberg REST catalog, Ranger, Atlas), the **streaming/ML**
services (Kafka, NiFi, MLflow) and the **console** have no upstream chart, so
they're local subcharts under `charts/` — all now ported:

| Local subchart  | Status   | Notes |
|-----------------|----------|-------|
| `iceberg-rest`  | ✅ done   | The SDX catalog spine. Trino's `iceberg` catalog is wired to it via `additionalCatalogs`; MinIO is pinned to a stable Service name so the catalog resolves it. |
| `atlas`         | ✅ done   | SDX lineage. Single container (embedded HBase + Solr), pinned by digest; `startupProbe` tolerates the slow boot. Heavy (~3Gi) — `--set atlas.enabled=false` to skip. |
| `ranger`        | ✅ done¹  | Policy server + UI **and** its Postgres metadata store (admin Deployment + db Deployment/Service/PVC). Stable Service names `ranger-admin` / `ranger-db`. |
| `kafka`         | ✅ done   | Single-node KRaft broker; advertised listener uses the stable `kafka` Service name. Default off. |
| `nifi`          | ✅ done   | Flow authoring, plain HTTP/anonymous; `startupProbe` on `/nifi`. Default off. |
| `mlflow`        | ✅ done   | Tracking server; SQLite metadata, artifacts in the MinIO `mlflow` bucket. Default off. |
| `console`       | ✅ done¹  | Control-plane API (Spring Boot). Env points at the in-cluster Services (Trino pinned to `trino` via `fullnameOverride`); a ServiceAccount + RBAC let it restart/scale Deployments. Locally-built image, default off. |
| `console-web`   | ✅ done¹  | Angular UI served by nginx, which reverse-proxies `/api` → `console-api:8090`. Locally-built image, default off; needs `console.enabled=true`. |
| `opdb`          | ✅ done   | Operational DB — HBase + Phoenix all-in-one; Phoenix Query Server on `opdb:8765`. Default off (heavy, standalone). |

¹ `ranger`, `console` and `console-web` have no published image — they're built
from `platform/governance/ranger`, `console/api` and `console/web`. **Build and
load before enabling** (that's why they default to `false`):

```bash
docker build -t odp/ranger-admin:2.4.0 platform/governance/ranger
docker build -t odp/console-api:latest  console/api
docker build -t odp/console-web:latest  console/web
kind load docker-image odp/ranger-admin:2.4.0      # or push to your registry
kind load docker-image odp/console-api:latest
kind load docker-image odp/console-web:latest
helm install odp platform/umbrella \
  --set ranger.enabled=true --set console.enabled=true --set console-web.enabled=true
```

The lakehouse (MinIO + Iceberg REST + Trino) + SDX (Atlas, Ranger) + the
streaming/ML and console subcharts now render as the whole platform on K8s.
`helm-ci` lints/templates it; `kind-ci` deploys the lakehouse subset and runs a
Trino round-trip on a real cluster.

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
