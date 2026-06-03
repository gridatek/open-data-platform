"""Phase 0 seed job — create and populate a demo Iceberg table from Spark.

This is the "Spark job" of the lakehouse core: it writes through the shared
Iceberg REST catalog so the same table is immediately queryable from Trino.

Run inside the Spark container (the spark-iceberg image ships spark-defaults
pointing `demo` at the REST catalog + MinIO, so no extra config is needed):

    docker compose exec spark spark-submit /home/iceberg/jobs/seed_lakehouse.py

or, from the host:  make seed
"""
from pyspark.sql import SparkSession

CATALOG = "demo"        # spark-iceberg image's built-in REST catalog
NAMESPACE = "smoke"
TABLE = f"{CATALOG}.{NAMESPACE}.events"

# (id, kind, ISO-8601 timestamp) — small, deterministic, four rows.
ROWS = [
    (1, "click", "2026-06-01 10:00:00"),
    (2, "view", "2026-06-01 10:01:30"),
    (3, "click", "2026-06-01 10:02:15"),
    (4, "purchase", "2026-06-01 10:05:00"),
]


def main() -> None:
    spark = SparkSession.builder.appName("phase0-seed").getOrCreate()

    spark.sql(f"CREATE NAMESPACE IF NOT EXISTS {CATALOG}.{NAMESPACE}")
    spark.sql(
        f"""
        CREATE TABLE IF NOT EXISTS {TABLE} (
            id   BIGINT,
            kind STRING,
            ts   TIMESTAMP
        ) USING iceberg
        """
    )

    # Idempotent reseed: start from empty so the row count is stable in CI.
    spark.sql(f"DELETE FROM {TABLE}")

    df = spark.createDataFrame(ROWS, "id BIGINT, kind STRING, ts STRING").selectExpr(
        "id", "kind", "CAST(ts AS TIMESTAMP) AS ts"
    )
    df.writeTo(TABLE).append()

    count = spark.table(TABLE).count()
    print(f"[seed] {TABLE} now has {count} rows")
    spark.table(TABLE).orderBy("id").show(truncate=False)

    spark.stop()


if __name__ == "__main__":
    main()
