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
| `mlflow`        | ✅ done   | Tracking server **+ its Postgres** (`mlflow-db`) for metadata; artifacts in the MinIO `mlflow` bucket. Default off. |
| `jupyterhub`    | ✅ done¹  | Multi-user notebooks (≈ CML). Dummy auth, local spawner. GHCR image, default on. |
| `console`       | ✅ done¹  | Control-plane API (Spring Boot). Env points at the in-cluster Services (Trino pinned to `trino` via `fullnameOverride`); a ServiceAccount + RBAC let it restart/scale Deployments. GHCR image, default on. |
| `console-web`   | ✅ done¹  | Angular UI served by nginx, which reverse-proxies `/api` → `console-api:8090`. GHCR image, default on; needs `console` (also on by default). |
| `opdb`          | ✅ done   | Operational DB — HBase + Phoenix all-in-one; Phoenix Query Server on `opdb:8765`. Default off (heavy, standalone). |

¹ `ranger`, `jupyterhub`, `console` and `console-web` have no upstream image —
they're built from `platform/governance/ranger`, `platform/ml/jupyterhub`,
`console/api` and `console/web` and **published to GHCR** by
[`publish-images.yml`](../../.github/workflows/publish-images.yml). Their chart
`image.repository` defaults to those `ghcr.io/gridatek/*` images, and the umbrella
now **defaults them on** — so `helm install odp platform/umbrella` deploys the
governed lakehouse + Ranger + the console out of the box.

> **Prerequisite:** the GHCR packages start **private**. Set them public (or add
> an `imagePullSecret`) so the cluster can pull, otherwise these pods
> `ImagePullBackOff`. Disable any you don't want with `--set <name>.enabled=false`.

To build + use them locally instead of pulling (e.g. on `kind`), tag them as the
chart's image and load:

```bash
docker build -t ghcr.io/gridatek/ranger-admin:2.4.0 platform/governance/ranger
docker build -t ghcr.io/gridatek/jupyterhub:latest  platform/ml/jupyterhub
docker build -t ghcr.io/gridatek/console-api:latest  console/api
docker build -t ghcr.io/gridatek/console-web:latest  console/web
for i in ranger-admin:2.4.0 jupyterhub:latest console-api:latest console-web:latest; do
  kind load docker-image ghcr.io/gridatek/$i
done
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
