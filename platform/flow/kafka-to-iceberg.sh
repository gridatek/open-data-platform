#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Kafka -> Iceberg streaming proof. Produce JSON events to a Kafka topic, run the
# Spark Structured Streaming ingest, then assert Trino reads the rows from the
# Iceberg table — Data Flow (Kafka) landing in the governed lakehouse.
#
# Run from quickstart/ with kafka + spark + the lakehouse (trino) up.
# Requires: docker compose. Spark version pinned for the kafka package.
# ───────────────────────────────────────────────────────────────
set -euo pipefail

DC="docker compose -f docker-compose.yml -f docker-compose.services.yml"
SPARK_KAFKA_PKG="org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.5"

echo "[k->i] producing 4 events to the 'events' topic"
printf '%s\n' \
  '{"id":1,"kind":"click","ts":"2026-06-01 10:00:00"}' \
  '{"id":2,"kind":"view","ts":"2026-06-01 10:01:30"}' \
  '{"id":3,"kind":"click","ts":"2026-06-01 10:02:15"}' \
  '{"id":4,"kind":"purchase","ts":"2026-06-01 10:05:00"}' \
  | ${DC} exec -T kafka /opt/kafka/bin/kafka-console-producer.sh \
      --bootstrap-server kafka:9092 --topic events

echo "[k->i] running the Spark structured-streaming ingest (Kafka -> Iceberg)"
${DC} exec -T spark spark-submit \
  --packages "${SPARK_KAFKA_PKG}" \
  /home/iceberg/jobs/stream_kafka_to_iceberg.py

echo "[k->i] asserting Trino reads the streamed Iceberg table"
N=$(${DC} exec -T trino trino --execute \
  "SELECT count(*) FROM iceberg.stream.events" | tr -d '"[:space:]')
echo "[k->i] rows in iceberg.stream.events = ${N}"
test "${N}" = "4"

echo "[k->i] OK — Kafka events landed in Iceberg via Spark, queryable from Trino."
