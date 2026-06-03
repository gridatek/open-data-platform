# 02 Data Analyst → CDP Data Analyst (CDP-4001)

The analyst's view of the governed lakehouse: write SQL against Iceberg tables
with **Trino**, build a dashboard in **Superset**, see how **Ranger** masks the
columns you're allowed to see, and discover data + lineage in **Atlas**.

The CDP Data Analyst exam explicitly tests Hive/Impala SQL, the Data Warehouse,
Data Visualization, Ranger and Atlas — i.e. exactly these four labs, with the OSS
tools standing in for their Cloudera counterparts.

## Labs

| # | Lab | Cert objective it maps to |
|---|-----|---------------------------|
| 01 | [SQL on Trino](lab-01-sql-on-trino.md) | Query the Data Warehouse: SELECT, GROUP BY, joins, window functions |
| 02 | [Column masking with Ranger](lab-02-column-masking.md) | Tabular security: column masking & row filtering |
| 03 | [A Superset dashboard](lab-03-superset-dashboard.md) | Data Visualization over the warehouse |
| 04 | [Discovery & lineage in Atlas](lab-04-atlas-discovery.md) | Metadata, search, lineage, classifications |

## Prerequisites

```bash
make all            # platform up (or: make services + make governance)
make seed           # the demo iceberg.smoke.events table
cd quickstart       # the labs run docker compose from here
```

> **On real CDP:** an analyst never provisions infrastructure — they're handed a
> CDW virtual warehouse and a governed catalog. Here, `make all` plays the part
> of the platform admin; the labs themselves stay in the analyst's lane (SQL,
> dashboards, reading policies and lineage).
