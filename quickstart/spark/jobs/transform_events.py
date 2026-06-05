"""Phase 1 (lineage) — a tiny transform with a clean input -> output edge.

Reads the seeded Iceberg table and writes a curated copy, so OpenLineage captures
a real source -> sink lineage (events -> events_curated) automatically. Used by
the auto-lineage proof: run this with the OpenLineage Spark listener, then bridge
the emitted events into Atlas.

    spark-submit --packages io.openlineage:openlineage-spark_2.12:1.24.2 \
      --conf spark.extraListeners=io.openlineage.spark.agent.OpenLineageSparkListener \
      ... /home/iceberg/jobs/transform_events.py
"""
from pyspark.sql import SparkSession

SRC = "demo.smoke.events"
DST = "demo.smoke.events_curated"


def main() -> None:
    spark = SparkSession.builder.appName("curate_events").getOrCreate()
    spark.sql(
        f"CREATE TABLE IF NOT EXISTS {DST} (id BIGINT, kind STRING) USING iceberg"
    )
    # Curate: keep id + kind (drop ts). A real read -> write so lineage is
    # source -> sink, not self-referential.
    spark.sql(f"INSERT OVERWRITE {DST} SELECT id, kind FROM {SRC}")
    print(f"[transform] {SRC} -> {DST}: {spark.table(DST).count()} rows")
    spark.stop()


if __name__ == "__main__":
    main()
