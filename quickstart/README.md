# quickstart — laptop subset

Phase 0 of the platform: a working **lakehouse core** in one command.

```
MinIO (S3)  →  Iceberg REST catalog  →  Trino (read) + Spark (write)
```

This is the spine everything else hangs off. Later phases graduate the same
components into the Helm charts under `platform/`.

## Run

```bash
cd quickstart
cp .env.example .env
docker compose up -d
```

Or with the `Makefile`:

```bash
make up      # copy .env (if missing) + docker compose up -d
make seed    # run the Spark job that writes the demo Iceberg table
make smoke   # read it back from Trino
make down    # stop and wipe volumes
```

| Service       | URL                     | Notes                          |
|---------------|-------------------------|--------------------------------|
| Trino         | http://localhost:8080   | SQL engine; any username, no password |
| Spark/Jupyter | http://localhost:8888   | write side, notebooks          |
| MinIO console | http://localhost:9001   | login with the `.env` creds    |
| Iceberg REST  | http://localhost:8181   | shared catalog API             |

Tear down with `docker compose down` (add `-v` to also wipe the MinIO volume).

## Smoke test — prove Spark writes and Trino reads the *same* table

Both engines talk to the **same** Iceberg REST catalog, so a table written
through one is visible to the other. Spark's built-in catalog is named `demo`;
Trino's (see `iceberg.properties`) is named `iceberg` — different local names,
one shared catalog server.

**1. Write a table from Spark** using the seed job (`make seed`, or directly):

```bash
docker compose exec spark spark-submit /home/iceberg/jobs/seed_lakehouse.py
```

This creates `demo.smoke.events` and writes four rows. (To do it by hand
instead, open `docker compose exec spark spark-sql` and run the equivalent
`CREATE NAMESPACE` / `CREATE TABLE` / `INSERT` statements.)

**2. Read it back from Trino** (same `smoke` namespace, via the `iceberg` catalog):

```bash
docker compose exec trino trino
```

```sql
SELECT * FROM iceberg.smoke.events ORDER BY id;
```

If both engines see the four rows, Phase 0 is green: one bucket, one Iceberg
table, written by Spark and queried by Trino through the shared REST catalog.
This same path is exercised on every push by `.github/workflows/quickstart-ci.yml`.

## Files

```
quickstart/
├── docker-compose.yml              # the 5 services (minio, init, rest, trino, spark)
├── .env.example                    # dev-only S3 creds + bucket name → copy to .env
├── Makefile                        # up / seed / smoke / down / logs / ps
├── trino/etc/catalog/
│   └── iceberg.properties          # Trino → REST catalog → MinIO
└── spark/
    ├── jobs/
    │   └── seed_lakehouse.py       # PySpark write job → demo.smoke.events
    └── notebooks/                  # mounted into Jupyter (http://localhost:8888)
```

> ⚠️ The credentials here are **local-dev only**. `.env` is gitignored; never
> reuse these values anywhere real.

## Phase 1 — governance overlay (Ranger + Atlas)

Add the SDX clone on top of the lakehouse to prove a Ranger policy masks a
column in a Trino query:

```bash
docker compose -f docker-compose.yml -f docker-compose.governance.yml up -d --build
```

See [`../platform/governance/README.md`](../platform/governance/README.md) for
the full walkthrough and the masking proof.

## Phase 3 — breadth of data services

Add analytic/orchestration services that consume the same governed lakehouse:

```bash
docker compose -f docker-compose.yml -f docker-compose.services.yml up -d
```

- **Superset** (BI) → http://localhost:8088 — see
  [`../platform/viz/README.md`](../platform/viz/README.md)
- **Airflow** (orchestration) → http://localhost:8082 — see
  [`../platform/engineering/README.md`](../platform/engineering/README.md)
- **MLflow** (experiment tracking) → http://localhost:5000 — see
  [`../platform/ml/README.md`](../platform/ml/README.md)
- **Kafka + NiFi** (streaming) → NiFi http://localhost:8095/nifi — see
  [`../platform/flow/README.md`](../platform/flow/README.md)
