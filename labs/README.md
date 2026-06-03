# labs — curriculum

Hands-on labs that teach the open data stack on **your own** platform, with a
callout in every lab bridging to the equivalent **Cloudera CDP** workflow and
its certification. Run the platform from `quickstart/`, then work the labs.

## Tracks → certifications

| Track | Folder | Cert target | Focus |
|-------|--------|-------------|-------|
| 00 Generalist | [`00-generalist`](00-generalist/) | CDP Generalist (CDP-0011) | The SDX model — one governed table, many engines |
| 01 Data Engineer | [`01-data-engineer`](01-data-engineer/) | Data Engineer (CDP-3002) | Spark transforms, Iceberg tables, Airflow |
| 02 Data Analyst | [`02-data-analyst`](02-data-analyst/) | Data Analyst (CDP-4001) | Trino SQL, Superset, Ranger masking, Atlas lineage |
| 03 Administrator | [`03-administrator`](03-administrator/) | Administrator (CDP-2001/5001) | Service lifecycle, Ranger admin, audits |
| 04 ML Engineer | [`04-ml-engineer`](04-ml-engineer/) | ML Engineer (CDP-60xx) | Notebooks, MLflow tracking + serving |

> Verify current Cloudera exam objectives before relying on the cert mapping —
> codes and weightings change.

## The callout convention

Every lab step that has a real-CDP analog carries a callout box, so the same
exercise teaches the OSS tool *and* the cert workflow:

> **On open-source:** run `SELECT ... FROM iceberg.smoke.events` in Trino.
> **On real CDP:** the same SQL runs in CDW (Hive/Impala) against an Iceberg
> table governed by the identical Ranger policy.

New labs start from [`LAB_TEMPLATE.md`](LAB_TEMPLATE.md).

## Prerequisites

- The platform up via `make all` (or `./bootstrap.sh`) — see the root `Makefile`.
- The demo table seeded: `make seed`.
