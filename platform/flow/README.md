# flow — NiFi + Kafka (≈ CDF)

Data Flow / streaming: **Kafka** as the broker and **NiFi** for visual flow
authoring. Together they're the ingestion path into the governed lakehouse.

## Run (Phase 3 overlay)

From `quickstart/`:

```bash
docker compose -f docker-compose.yml -f docker-compose.services.yml up -d kafka nifi
```

- **Kafka** — `kafka:9092` in-network (KRaft, single node, no ZooKeeper)
- **NiFi** — http://localhost:8095/nifi (plain HTTP, anonymous — laptop only)

## Kafka round-trip (the proof)

Kafka's CLI lives in the container; run it via `docker compose exec`:

```bash
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 --create --topic odp-events \
  --partitions 1 --replication-factor 1

echo "hello-odp" | docker compose exec -T kafka \
  /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic odp-events

docker compose exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 --topic odp-events --from-beginning --max-messages 1
```

If `hello-odp` comes back, the broker works end-to-end. CI runs exactly this in
`.github/workflows/services-ci.yml` (the `streaming` job), and also asserts the
NiFi REST/UI is reachable.

## ⚠️ Rough edges

- **NiFi runs in plain-HTTP, anonymous mode** (`NIFI_WEB_HTTP_PORT`) for an
  easy laptop UI. NiFi 1.x/2.x default to HTTPS + single-user auth — that's what
  a real deployment uses.
- **Kafka → Iceberg is wired.** The headline goal — events from Kafka landing in
  the governed lakehouse — runs as a **Spark Structured Streaming** ingest
  (`quickstart/spark/jobs/stream_kafka_to_iceberg.py`): produce JSON to the
  `events` topic, Spark drains it (`trigger=availableNow`) into
  `demo.stream.events`, and Trino reads `iceberg.stream.events`. Proven by
  `streaming-ci` (`platform/flow/kafka-to-iceberg.sh`). NiFi also runs a minimal
  automated flow via its REST API (`platform/flow/nifi-flow.sh`, `flow-ci`); a
  NiFi-native `PutIceberg` sink is a further variant.
- Kafka storage is ephemeral (no volume) — fine for the demo/CI; add a volume
  for persistence.
