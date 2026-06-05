"""Kafka -> Iceberg streaming ingest (Spark Structured Streaming).

Reads JSON events from the `events` Kafka topic and appends them to the Iceberg
table `demo.stream.events` through the shared REST catalog — so the same governed
table is immediately queryable from Trino (`iceberg.stream.events`). This is the
streaming counterpart of the batch seed: Data Flow (Kafka) -> the lakehouse.

Uses trigger=availableNow: it drains the records currently in the topic, then
stops — batch-like, so a smoke test can assert the row count.

Run inside the spark container (the spark-iceberg image's spark-defaults already
points the `demo` catalog at the REST catalog + MinIO):

    spark-submit \
      --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.5 \
      /home/iceberg/jobs/stream_kafka_to_iceberg.py
"""
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, from_json
from pyspark.sql.types import LongType, StringType, StructField, StructType

CATALOG = "demo"          # spark-iceberg image's built-in REST catalog
TABLE = f"{CATALOG}.stream.events"
TOPIC = "events"
BOOTSTRAP = "kafka:9092"

EVENT_SCHEMA = StructType(
    [
        StructField("id", LongType()),
        StructField("kind", StringType()),
        StructField("ts", StringType()),
    ]
)


def main() -> None:
    spark = SparkSession.builder.appName("kafka-to-iceberg").getOrCreate()

    spark.sql(f"CREATE NAMESPACE IF NOT EXISTS {CATALOG}.stream")
    spark.sql(
        f"""
        CREATE TABLE IF NOT EXISTS {TABLE} (
            id   BIGINT,
            kind STRING,
            ts   TIMESTAMP
        ) USING iceberg
        """
    )

    raw = (
        spark.readStream.format("kafka")
        .option("kafka.bootstrap.servers", BOOTSTRAP)
        .option("subscribe", TOPIC)
        .option("startingOffsets", "earliest")
        .load()
    )

    events = (
        raw.select(from_json(col("value").cast("string"), EVENT_SCHEMA).alias("e"))
        .select(
            col("e.id").alias("id"),
            col("e.kind").alias("kind"),
            col("e.ts").cast("timestamp").alias("ts"),
        )
        .where(col("id").isNotNull())
    )

    query = (
        events.writeStream.format("iceberg")
        .outputMode("append")
        .option("checkpointLocation", "/tmp/ckpt-kafka-iceberg")
        .trigger(availableNow=True)
        .toTable(TABLE)
    )
    query.awaitTermination()
    print(f"[stream] drained Kafka topic '{TOPIC}' -> {TABLE}")
    spark.stop()


if __name__ == "__main__":
    main()
