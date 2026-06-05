# Running the platform for real

The defaults target a laptop (docker-compose) or a single `kind` node — dev
credentials, default-off heavy services, `ClusterIP` only. This guide collects
what to change before running the umbrella Helm chart on a real cluster. It's a
checklist, not a turnkey production config.

## 1. Images (GHCR)

`ranger-admin`, `console-api`, `console-web`, `jupyterhub`, `superset`, `mlflow`
and `airflow` are built and pushed to GHCR by
[`publish-images.yml`](../.github/workflows/publish-images.yml). The packages
start **private**, so either:

- make the packages **public** (GitHub → package → Package settings → visibility), or
- create an image pull secret and reference it:

  ```bash
  kubectl -n odp create secret docker-registry ghcr \
    --docker-server=ghcr.io --docker-username=<user> --docker-password=<token>
  ```

  then add it where each chart expects it (the upstream charts take
  `global.imagePullSecrets`; the local subcharts run public base images except
  the ones above).

Otherwise those pods land in `ImagePullBackOff`. To avoid the registry entirely
on `kind`, build + `kind load` the images (see `platform/umbrella/README.md`).

## 2. Credentials

Every password/key is a Kubernetes Secret, with dev values set from the
`*Credentials` / `appSecretKeys` blocks in `values.yaml`:

| Secret | Used by |
|--------|---------|
| `odp-s3-credentials` | minio, iceberg-rest, trino, spark, mlflow |
| `odp-ranger-credentials` | ranger admin + db, console |
| `odp-mlflow-credentials` | mlflow backend store |
| `odp-atlas-credentials` | atlas health probes |
| `odp-app-secret-keys` | superset + airflow session keys |

For real use, **pre-create your own Secrets** and set `create: false` +
`secretName: <yours>` on each block (keep the documented key names), or override
the values with `--set`/a values file kept out of git. Don't ship the defaults.

## 3. Services to enable

The base install is the governed lakehouse + Ranger + console. Heavy/optional
services are default **off** — enable what you need:

```bash
helm install odp platform/umbrella -n odp --create-namespace \
  --set superset.enabled=true --set airflow.enabled=true \
  --set mlflow.enabled=true   --set spark.enabled=true
```

`atlas` is on by default but heavy (embedded HBase + Solr); give it real memory
or `--set atlas.enabled=false`. `opdb`, `kafka`, `nifi` are standalone/optional.

## 4. Ingress + TLS

Services are `ClusterIP` by default (reach them with `kubectl port-forward`).
For external access, install an ingress controller (e.g. ingress-nginx) and turn
on the bundled Ingress:

```bash
--set ingress.enabled=true --set ingress.baseDomain=odp.example.com \
--set ingress.className=nginx --set ingress.tls.enabled=true
```

Point DNS (`*.odp.example.com`) at the controller. Trim `ingress.services` to the
services you've enabled.

## 5. Sizing & persistence

- The dev values trim memory **requests** to fit a single small node (MinIO,
  Trino heap at 2G, the bundled Postgres instances). Raise them for real load.
- Trino runs `workers: 2` — scale via `trino.server.workers`.
- Stateful data (MinIO, the Postgres metadata stores, Ranger/MLflow DBs) uses
  PVCs — set a real `storageClass` and back them up.

## 6. What's proven vs. what isn't

`kind-ci` proves every service comes up and works on a real cluster (lakehouse
round-trip, Ranger masking, Spark/Airflow/Superset/MLflow/console/jupyterhub).
`atlas-on-kind` is best-effort — Atlas is too heavy to reach Ready in a CI
runner's window, so it's validated by lint/template + the local proof, not gated.
