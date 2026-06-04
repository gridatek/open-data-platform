# opdb — HBase + Phoenix

Operational Database (≈ CDP Operational Database): a wide-column store
(**HBase**) with a SQL layer (**Phoenix**). The OLTP-ish counterpart to the
analytic engines — random-access reads/writes by key, queried with SQL.

```
opdb/
└── smoke.sh   # create a Phoenix table, upsert rows, read one back
```

The laptop subset runs the community `boostport/hbase-phoenix-all-in-one`
image: HBase master + regionserver + ZooKeeper + the Phoenix Query Server in a
single container (single node, no auth).

## Run (standalone overlay)

From `quickstart/` — the Operational DB doesn't depend on the lakehouse:

```bash
docker compose -f docker-compose.opdb.yml up -d
../platform/opdb/smoke.sh
```

Phoenix Query Server (thin JDBC): `localhost:8765`.

`smoke.sh` runs, via the Phoenix fat client inside the container:

```sql
CREATE TABLE IF NOT EXISTS odp_events (id INTEGER PRIMARY KEY, kind VARCHAR);
UPSERT INTO odp_events VALUES (1, 'purchase');
SELECT kind FROM odp_events WHERE id = 1;   -- expects 'purchase'
```

CI runs this in [`.github/workflows/opdb-ci.yml`](../../.github/workflows/opdb-ci.yml).

## ⚠️ Rough edges

- **Fat client, not thin.** The smoke connects with `sqlline.py` (→ ZooKeeper),
  not `sqlline-thin.py` (→ Phoenix Query Server) — the thin client's wrapper
  class is missing in this image. The PQS port (8765) is still exposed for
  external thin-JDBC drivers.
- **`HBASE_CONF_DIR=/opt/hbase/conf`** must be set for the client so its
  `phoenix.schema.isNamespaceMappingEnabled` matches the server (otherwise
  `ERROR 726`). `smoke.sh` handles this.
- **Cold start.** HBase must assign its regions before the first Phoenix
  connection can bootstrap `SYSTEM.CATALOG`; `smoke.sh` retries until ready.
- HBase + Phoenix here are **2.0 / 5.0** (old but stable for a demo). Not wired
  into the umbrella Helm chart yet — that's the next step.
