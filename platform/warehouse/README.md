# warehouse — Trino + Iceberg (≈ CDW)

Data Warehouse: Trino querying Iceberg tables (Impala optional).

- **Modern (default):** Trino over the shared **Iceberg** REST catalog. See the
  runnable analytics lab in `run-analytics-sql.sh` and the catalog config in
  `quickstart/trino/etc/catalog/iceberg.properties`.
- **Legacy (learning only):** `hive/` — a Hive Metastore + Trino `hive` catalog,
  kept *only* to show the old table format and the Hive → Iceberg migration.
  Off by default; start with `make hive`. ⚠️ Don't use it for new work.
