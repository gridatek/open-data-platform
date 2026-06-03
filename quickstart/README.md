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

**1. Write a table from Spark.** Open a SQL shell in the Spark container:

```bash
docker compose exec spark spark-sql
```

```sql
CREATE NAMESPACE IF NOT EXISTS demo.smoke;
CREATE TABLE demo.smoke.events (id BIGINT, kind STRING) USING iceberg;
INSERT INTO demo.smoke.events VALUES (1, 'click'), (2, 'view');
```

**2. Read it back from Trino** (same `smoke` namespace, via the `iceberg` catalog):

```bash
docker compose exec trino trino
```

```sql
SELECT * FROM iceberg.smoke.events ORDER BY id;
```

If both engines see the two rows, Phase 0 is green: one bucket, one Iceberg
table, written by Spark and queried by Trino through the shared REST catalog.
This same path is exercised on every push by `.github/workflows/quickstart-ci.yml`.

## Files

```
quickstart/
├── docker-compose.yml              # the 5 services (minio, init, rest, trino, spark)
├── .env.example                    # dev-only S3 creds + bucket name → copy to .env
├── trino/etc/catalog/
│   └── iceberg.properties          # Trino → REST catalog → MinIO
└── spark/notebooks/                # mounted into Jupyter (http://localhost:8888)
```

> ⚠️ The credentials here are **local-dev only**. `.env` is gitignored; never
> reuse these values anywhere real.
