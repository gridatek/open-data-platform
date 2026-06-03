# 04 ML Engineer — Lab 1: Notebooks on the lakehouse

**Time:** ~20 min · **Prereqs:** `make core`, `make seed`, `cd quickstart`

## Goal

Use a notebook as your ML workbench: read governed Iceberg data with Spark, shape
it into features, and pull it into pandas — the first step of any model.

Open Jupyter at **http://localhost:8888** (served by the `spark-iceberg`
container; a `spark` session is pre-created in notebooks).

## Steps

1. **Read a governed table into Spark.** In a new notebook cell:

   ```python
   df = spark.table("demo.smoke.events")
   df.show()
   ```

   `demo` is Spark's name for the shared REST catalog — the same table Trino sees
   as `iceberg.smoke.events`.

   > **On open-source:** the notebook reads Iceberg through the shared catalog.
   > **On real CDP:** a CML session reads an SDX-governed table the same way.

2. **Engineer a feature** — a binary label "was it a purchase?":

   ```python
   from pyspark.sql import functions as F

   feats = (
       spark.table("demo.smoke.events")
       .withColumn("is_purchase", (F.col("kind") == "purchase").cast("int"))
       .select("id", "kind", "is_purchase")
   )
   feats.show()
   ```

3. **Pull to pandas** for scikit-learn (small data — fine to collect):

   ```python
   pdf = feats.toPandas()
   pdf.head()
   ```

4. **(CLI equivalent)** prefer the shell? The same works headless:

   ```bash
   docker compose exec spark python -c "
   from pyspark.sql import SparkSession
   spark = SparkSession.builder.getOrCreate()
   spark.table('demo.smoke.events').show()
   "
   ```

   > **On real CDP:** CML notebooks and jobs share one runtime; you prototype in a
   > notebook, then run the same code as a job — a tested ML workflow.

## Check yourself

- [ ] `spark.table("demo.smoke.events")` shows the 4 seeded rows (step 1).
- [ ] `is_purchase` is 1 for the `purchase` row, else 0 (step 2).
- [ ] `pdf` is a pandas DataFrame (step 3).

## Going further

- Join `iceberg.analytics.orders` (Data Analyst Lab 1) for richer features.
- Next: [Lab 2 — experiment tracking](lab-02-experiment-tracking.md).
