# 02 Data Analyst — Lab 3: A Superset dashboard

**Time:** ~30 min · **Prereqs:** Lab 1 done (the `orders` table exists),
Superset up, `cd quickstart`

## Goal

Turn governed SQL into a dashboard. Superset reads the lakehouse *through Trino*,
so everything you visualize honors the same Ranger policies — BI on governed data.

> **Runnable demo (CI-proven):** the click-path below (dataset → chart →
> dashboard) is also scripted end-to-end against the Superset REST API in
> `platform/viz/build-dashboard.sh`, which `analyst-ci` runs on each push. Prefer
> clicking to learn it; run the script to prove it: after `register-trino.sh`,
> `../platform/viz/build-dashboard.sh` builds and verifies the same
> `Sales overview` dashboard.

Bring up Superset and register the Trino connection (idempotent):

```bash
docker compose -f docker-compose.yml -f docker-compose.services.yml up -d superset
../platform/viz/register-trino.sh
```

Open http://localhost:8088 — log in `admin` / `admin`.

## Steps

1. **Confirm the connection.** Settings → Database Connections — you'll see
   `trino-odp` (`trino://admin@trino:8080/iceberg`), added by the script.

   > **On open-source:** Superset talks Iceberg via Trino's SQLAlchemy dialect.
   > **On real CDP:** Cloudera Data Visualization connects to a CDW virtual
   > warehouse — same pattern, governed source.

2. **Create a dataset.** Datasets → **+ Dataset** → database `trino-odp`,
   schema `analytics`, table `orders`. Save.

3. **Build a chart.** From the dataset, **Create Chart** → *Bar Chart*:
   - Dimension: `region`
   - Metric: `SUM(amount)`
   - Run, then **Save** as `Revenue by region`.

4. **Add a second chart** → *Table* or *Pie*:
   - Dimension: `product`, Metric: `COUNT(*)` → save as `Orders by product`.

5. **Assemble a dashboard.** Dashboards → **+ Dashboard**, drag both charts in,
   name it `Sales overview`, **Save**.

6. **(Optional) SQL Lab.** SQL → SQL Lab, database `trino-odp`, run:

   ```sql
   SELECT region, count(*) AS orders, round(sum(amount),2) AS revenue
   FROM iceberg.analytics.orders GROUP BY region ORDER BY revenue DESC
   ```

   Use **Create Chart from SQL** to skip straight to a viz.

   > **On real CDP:** SQL Lab ↔ the CDW SQL editor / Hue; the dashboarding flow
   > mirrors Cloudera Data Visualization, a tested objective.

## Check yourself

- [ ] `trino-odp` connection is listed (step 1).
- [ ] `Revenue by region` shows US highest (step 3).
- [ ] The `Sales overview` dashboard renders both charts (step 5).

## Going further

- Point a dataset at `iceberg.smoke.events` and notice masking still applies if
  you connect as a masked user.
- Next: [Lab 4 — discovery & lineage in Atlas](lab-04-atlas-discovery.md).
