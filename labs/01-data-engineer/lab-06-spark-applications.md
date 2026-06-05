# 01 Data Engineer — Lab 6: Build & submit a Spark application

**Time:** ~35 min · **Prereqs:** `make core`, `cd quickstart`, the demo table
seeded (`docker compose exec spark spark-submit /home/iceberg/jobs/seed_lakehouse.py`)

## Goal

The earlier labs used the interactive `spark-sql` shell. Real pipelines run as
**submitted applications** — a script or a compiled JAR you hand to the cluster
with `spark-submit`. That's exactly what **Cloudera Data Engineering (CDE)** is: a
service for submitting Spark jobs. Here you'll write and submit one **two ways** —
**PySpark** (a `.py` file) and **Java** (a built JAR) — both reading and writing
the governed Iceberg lakehouse.

> **Why it already "just works":** the `spark-iceberg` image ships a
> `spark-defaults.conf` that wires the `demo` catalog to the Iceberg REST catalog
> + MinIO. So your app only writes **SQL against `demo.…`** — no catalog/S3
> boilerplate in the application code. (On a real cluster you'd pass that config
> as `--conf` or in the CDE job definition.)

---

## Part A — a PySpark application

A Spark application is just a script with a `SparkSession`. The repo's jobs are
exactly this — open `quickstart/spark/jobs/transform_events.py`:

```python
from pyspark.sql import SparkSession

def main():
    spark = SparkSession.builder.appName("curate_events").getOrCreate()
    spark.sql("CREATE TABLE IF NOT EXISTS demo.smoke.events_curated (id BIGINT, kind STRING) USING iceberg")
    spark.sql("INSERT OVERWRITE demo.smoke.events_curated SELECT id, kind FROM demo.smoke.events")
    spark.stop()

if __name__ == "__main__":
    main()
```

**Submit it** (vs. typing into the shell):

```bash
docker compose exec spark spark-submit /home/iceberg/jobs/transform_events.py
```

`spark-submit` builds the session, runs `main()`, and exits — the same lifecycle a
CDE job runs. **Confirm a different engine sees the output:**

```bash
docker compose exec trino trino \
  --execute "SELECT count(*) FROM iceberg.smoke.events_curated"
```

**Passing configuration / arguments.** Real jobs are parameterised. You add
`--conf` flags (or `sys.argv` args) on the submit line — e.g. attaching the
OpenLineage listener (see `register-lineage-auto.sh`):

```bash
docker compose exec spark spark-submit \
  --packages io.openlineage:openlineage-spark_2.12:3.5.5 \
  --conf spark.extraListeners=io.openlineage.spark.agent.OpenLineageSparkListener \
  /home/iceberg/jobs/transform_events.py
```

> The repo's other PySpark apps — `seed_lakehouse.py`, `iceberg_features.py`,
> `stream_kafka_to_iceberg.py`, `maintain_lakehouse.py` — are all worked examples
> of submitted applications.

---

## Part B — a Java (JVM) application

Production Spark jobs are often **compiled JVM apps** (Java/Scala) packaged as a
JAR. The repo ships one at `quickstart/spark/apps/java/`.

**The app** (`src/main/java/com/gridatek/odp/IcebergApp.java`) — same SQL, in Java:

```java
SparkSession spark = SparkSession.builder().appName("iceberg-java-app").getOrCreate();
spark.sql("CREATE TABLE IF NOT EXISTS demo.de.events_java (id BIGINT, kind STRING) USING iceberg");
spark.sql("INSERT OVERWRITE demo.de.events_java SELECT id, kind FROM demo.smoke.events");
spark.stop();
```

**The build** (`pom.xml`). Spark + Iceberg are already on the cluster classpath,
so the dependency is `provided` and the JAR stays thin (no fat-jar shading). The
Spark/Scala versions match the image (Spark **3.5.5** / Scala **2.12**):

```xml
<dependency>
  <groupId>org.apache.spark</groupId>
  <artifactId>spark-sql_2.12</artifactId>
  <version>3.5.5</version>
  <scope>provided</scope>
</dependency>
```

**Build the JAR** (no Maven on your host? build it in a Maven container):

```bash
cd quickstart/spark/apps/java
docker run --rm -v "$PWD":/app -w /app maven:3.9-eclipse-temurin-17 mvn -q package
# -> target/iceberg-java-app-1.0.jar
```

**Submit it** — copy the JAR into the Spark container, then `spark-submit --class`:

```bash
docker cp target/iceberg-java-app-1.0.jar odp-spark:/tmp/app.jar
cd ../../../..              # back to quickstart/
docker compose exec spark spark-submit \
  --class com.gridatek.odp.IcebergApp /tmp/app.jar
```

**Confirm Trino reads the Java app's output:**

```bash
docker compose exec trino trino \
  --execute "SELECT id, kind FROM iceberg.de.events_java ORDER BY id"
```

Four rows — written by a compiled Java application, read by Trino, through the
same governed catalog.

---

## What you proved

- A Spark application is a `SparkSession` + your logic, handed to the cluster with
  `spark-submit` — the unit of work a CDE service schedules.
- The **same job** works as a **PySpark script** or a **Java JAR**; the engine and
  the language are interchangeable, the governed Iceberg layer is the constant.
- `--conf` / `--packages` / `--class` are how you parameterise and target a
  submission.

> **On real CDP:** each of these is a **CDE Spark job** — you'd upload the script
> or JAR, set resources + config in the job definition, and run/schedule it; the
> Spark-on-Kubernetes plumbing is managed for you.

CI proves this end to end in `.github/workflows/spark-app-ci.yml` (builds the Java
JAR, submits both apps, asserts Trino reads the output).
