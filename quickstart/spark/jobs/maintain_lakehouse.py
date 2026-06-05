"""Phase 0 (ops) — Iceberg table maintenance: compaction + snapshot expiry.

Lots of small INSERT/DELETE commits leave small data files and a long snapshot
history. This runs the standard Iceberg maintenance procedures on
demo.smoke.events — rewrite_data_files (compact) and expire_snapshots (prune old
snapshots) — and confirms the data survives. The same procedures keep a real
lakehouse healthy. Backs data-engineer lab-02.

    docker compose exec spark spark-submit /home/iceberg/jobs/maintain_lakehouse.py
"""
from pyspark.sql import SparkSession

CATALOG = "demo"
TABLE = f"{CATALOG}.smoke.events"


def main() -> None:
    spark = SparkSession.builder.appName("lakehouse-maintenance").getOrCreate()

    before_rows = spark.table(TABLE).count()
    print(f"[maintain] before: rows={before_rows}")

    # 1) Compact small files into fewer, larger ones. The procedure returns the
    #    number of files rewritten.
    res = spark.sql(
        f"CALL {CATALOG}.system.rewrite_data_files(table => 'smoke.events')"
    ).collect()
    print(f"[maintain] rewrite_data_files -> {res}")

    # 2) Expire old snapshots, keeping only the most recent. Returns how many
    #    data/manifest files were deleted.
    res = spark.sql(
        f"""
        CALL {CATALOG}.system.expire_snapshots(
            table => 'smoke.events',
            older_than => TIMESTAMP '2999-01-01 00:00:00',
            retain_last => 1
        )
        """
    ).collect()
    print(f"[maintain] expire_snapshots -> {res}")

    after_rows = spark.table(TABLE).count()
    print(f"[maintain] after:  rows={after_rows}")

    # Data must survive maintenance.
    assert after_rows == before_rows, f"row count changed: {before_rows} -> {after_rows}"
    print("[maintain] OK — compacted + expired snapshots, data intact")
    spark.stop()


if __name__ == "__main__":
    main()
