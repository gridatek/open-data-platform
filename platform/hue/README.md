# Apache Hue — the SQL editor over the lakehouse (≈ CDP CDW SQL editor / Hue)

Hue is the web **SQL editor** for the platform's Trino engine — the same role
Hue plays in a Cloudera cluster (the SQL editor in CDW), and the editor
counterpart of Superset's SQL Lab. You write SQL against the governed Iceberg
tables and get results in the browser; no dashboards, just the query surface.

> Scope: this wires Hue's **Trino interpreter** only, against the `iceberg`
> catalog. Hue can also front Phoenix/Hive/Impala — add more interpreters under
> `[notebook]` in [`hue.ini`](hue.ini) as the platform grows.

## Run it (docker-compose)

Hue needs Trino, so overlay it on the base lakehouse:

```bash
make hue
# or, by hand:
docker compose --project-directory quickstart \
  -f quickstart/docker-compose.yml \
  -f quickstart/docker-compose.hue.yml up -d
```

Open **http://localhost:8889** (host 8889 — 8888 is Spark's Jupyter in the core
lakehouse). The **first login becomes the superuser** (Hue has no demo user).
Then in the editor pick the **Trino** dialect and run, e.g.:

```sql
SELECT * FROM iceberg.smoke.events;
```

## On Kubernetes (umbrella chart)

The same editor is packaged as a local subchart at
[`platform/umbrella/charts/hue`](../umbrella/charts/hue) — `gethue/hue` plus a
ConfigMap carrying the `hue.ini` overlay (Trino URL pointed at the in-cluster
`trino` Service). Default **off**:

```bash
helm upgrade --install odp platform/umbrella -n odp --create-namespace \
  --set hue.enabled=true
kubectl -n odp port-forward svc/hue 8888:8888   # then http://localhost:8888
```

Proven on `kind` by the `hue-on-kind` job in `kind-ci.yml` (backed by
[`hue-on-kind.sh`](hue-on-kind.sh)): Hue boots and reports healthy
(`/desktop/debug/is_alive` → 200) with its Trino interpreter wired to the
lakehouse.

## How it's wired

- **`hue.ini`** — a `z-`prefixed override (Hue merges `*.ini` alphabetically, so
  it lands last and overrides the image's shipped config). It strips Hue to the
  SQL editor via `app_blacklist` (no HDFS/Oozie/HBase apps — this platform
  doesn't run them) and declares one `[[[trino]]]` interpreter. Hue's **native
  `trino` interface** talks to the coordinator's REST API directly, so no extra
  driver is needed in the image.
- Metadata (users, saved queries, history) lives in an **embedded SQLite** DB —
  fine for a laptop/dev; point `[[database]]` at Postgres for anything real.

## Caveats (laptop reality)

- **First login is the superuser** — there's no seeded account.
- **SQLite is ephemeral** on K8s (in-pod) — saved queries don't survive a pod
  restart. Use Postgres if you need persistence.
- Like the other UIs behind Knox, deep links may need response-rewrite rules;
  the gateway route is a plain passthrough (see `platform/knox`).

## Through Knox

The Knox compose topology proxies Hue at
`https://localhost:8443/gateway/odp/hue/` (service definition under
`platform/knox/services/hue/`). On Kubernetes, add a `HUE` backend to the Knox
subchart's `backends` once that chart is in place.
