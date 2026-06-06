# Learning path

A guided order for working through this repo as a curriculum. The platform teaches
one idea — **one governed Iceberg table, many interchangeable engines** (the SDX
model) — and every track is depth on one slice of that picture. Walk the tracks in
the order below and that idea compounds instead of arriving piecemeal.

> Each lab carries an **On open-source / On real CDP** callout, so the same
> exercise teaches the OSS tool *and* its Cloudera certification workflow. Labs
> marked **CI-proven** below have a runnable backing script that a CI job executes
> on every push — the steps you follow by hand are the same ones proven green.

## Step 0 — bring the platform up

```bash
make all       # services + governance
make seed      # the demo iceberg.smoke.events table
make ps        # sanity-check what's running
cd quickstart  # every lab runs docker compose from here
```

Reset buttons when something looks wrong: `make logs`, then `make down`.

## The order

| # | Track | Start with | Why here |
|---|-------|-----------|----------|
| 1 | [00 Generalist](../labs/00-generalist/) | [The SDX model](../labs/00-generalist/lab-01-the-sdx-model.md) | The single mental model: Spark writes a table; Trino & Superset read it; Ranger masks a column; Atlas shows lineage — all over **one** Iceberg table. Everything else specializes this. |
| 2 | [02 Data Analyst](../labs/02-data-analyst/) | [SQL on Trino](../labs/02-data-analyst/lab-01-sql-on-trino.md) | The most reliable track to follow — all four labs are **CI-proven**. SQL → Superset dashboard → Ranger masking → Atlas discovery. |
| 3 | [01 Data Engineer](../labs/01-data-engineer/) | track README | The *producer* side of the table the analyst reads: Spark transforms, Iceberg maintenance, Airflow orchestration. |
| 4 | [03 Administrator](../labs/03-administrator/) | track README | Operating the platform: service lifecycle, Ranger admin, audits. |
| 5 | [04 ML Engineer](../labs/04-ml-engineer/) | track README | Notebooks, MLflow tracking + serving on top of the governed data. |

## What "CI-proven" means here

For some labs there's a runnable script that builds and asserts the lab's outcome,
executed by a GitHub Actions workflow on every push. You can run the same script
locally to prove the lab end-to-end. The data-analyst track is fully covered:

| Lab | Backing script | CI workflow |
|-----|----------------|-------------|
| Analyst · SQL on Trino | `platform/warehouse/run-analytics-sql.sh` | `analyst-ci` |
| Analyst · Column masking | `platform/governance/load-policies.sh` | `governance-ci` |
| Analyst · Superset dashboard | `platform/viz/build-dashboard.sh` | `analyst-ci` |
| Analyst · Atlas discovery | `platform/governance/atlas/register-lineage.sh` | `atlas-ci` |

Look for a `> **Runnable demo (CI-proven):**` blockquote inside a lab — it names
the script and tells you when to run it.

## How to get the most out of a lab

1. **Read both callout boxes.** The *On real CDP* box is the cert objective; the
   *On open-source* box is what you actually run.
2. **Do it by hand first**, clicking/typing the steps — that's how it sticks.
3. **Then run the backing script** (if the lab has one) to see the same outcome
   proven deterministically.
4. **Break it on purpose** — change a value, re-run, watch the assertion fail.
   The scripts are idempotent and safe to re-run.

## Suggested first session

Do **Generalist lab-01** end to end. Once "one table, many engines" clicks —
Spark writing it, Trino and Superset reading it, Ranger masking it, Atlas tracing
it — every other track reads as depth on one of those engines rather than a new
system to learn.
