# 02 Data Analyst — Lab 1: SQL on Trino

**Time:** ~25 min · **Prereqs:** platform up, `cd quickstart`

## Goal

Use Trino as your Data Warehouse: create a governed Iceberg table, load some
rows, and answer real questions with `GROUP BY`, joins, and window functions —
the SQL the Data Analyst exam lives on.

Open a Trino shell (everything below runs inside it):

```bash
docker compose exec trino trino
```

## Steps

1. **Create a schema and an `orders` table** in the shared catalog.

   ```sql
   CREATE SCHEMA IF NOT EXISTS iceberg.analytics;

   CREATE TABLE iceberg.analytics.orders (
     id       bigint,
     region   varchar,
     product  varchar,
     amount   double,
     ts       timestamp(6)
   );
   ```

   > **On open-source:** Trino writes Iceberg DDL through the REST catalog — the
   > table is immediately visible to Spark, Superset, anything.
   > **On real CDP:** the same `CREATE TABLE ... ` runs in CDW (Impala/Hive) and
   > registers in the SDX catalog.

2. **Load rows.**

   ```sql
   INSERT INTO iceberg.analytics.orders VALUES
     (1,'EU','widget',  19.99, TIMESTAMP '2026-06-01 09:00:00'),
     (2,'EU','gadget',  49.50, TIMESTAMP '2026-06-01 09:30:00'),
     (3,'US','widget',  21.00, TIMESTAMP '2026-06-01 10:00:00'),
     (4,'US','gizmo',  120.00, TIMESTAMP '2026-06-01 10:15:00'),
     (5,'US','gadget',  47.25, TIMESTAMP '2026-06-01 11:00:00'),
     (6,'APAC','widget',18.75, TIMESTAMP '2026-06-01 11:30:00'),
     (7,'APAC','gizmo',115.00, TIMESTAMP '2026-06-01 12:00:00'),
     (8,'EU','gizmo', 118.00, TIMESTAMP '2026-06-01 12:30:00'),
     (9,'US','widget', 20.50, TIMESTAMP '2026-06-01 13:00:00'),
     (10,'APAC','gadget',46.00,TIMESTAMP '2026-06-01 13:30:00');
   ```

3. **Aggregate** — revenue and order count by region:

   ```sql
   SELECT region, count(*) AS orders, round(sum(amount), 2) AS revenue
   FROM iceberg.analytics.orders
   GROUP BY region
   ORDER BY revenue DESC;
   ```

   > **On open-source / On real CDP:** identical ANSI SQL — Trino here, Impala in
   > CDW. The skill transfers one-to-one.

4. **Join** to a small lookup table:

   ```sql
   CREATE TABLE iceberg.analytics.product_tier (product varchar, tier varchar);
   INSERT INTO iceberg.analytics.product_tier VALUES
     ('widget','budget'), ('gadget','mid'), ('gizmo','premium');

   SELECT t.tier, round(sum(o.amount), 2) AS revenue
   FROM iceberg.analytics.orders o
   JOIN iceberg.analytics.product_tier t ON o.product = t.product
   GROUP BY t.tier
   ORDER BY revenue DESC;
   ```

5. **Window function** — each order's share of its region's revenue:

   ```sql
   SELECT region, product, amount,
          round(100.0 * amount / sum(amount) OVER (PARTITION BY region), 1) AS pct_of_region
   FROM iceberg.analytics.orders
   ORDER BY region, pct_of_region DESC;
   ```

   > **On real CDP:** window functions are a tested Data Analyst objective; CDW
   > runs these the same way.

## Check yourself

- [ ] `US` is the top region by revenue (step 3).
- [ ] `premium` is the top tier by revenue (step 4).
- [ ] Each region's `pct_of_region` sums to ~100 (step 5).

## Going further

- Time-bucket the orders: `GROUP BY date_trunc('hour', ts)`.
- Inspect Iceberg's snapshots: `SELECT * FROM iceberg.analytics."orders$snapshots";`
- Next: [Lab 2 — column masking](lab-02-column-masking.md), where governance
  changes what *you* are allowed to see.
