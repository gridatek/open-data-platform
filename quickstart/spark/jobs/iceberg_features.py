"""Iceberg feature demo — the lakehouse moves that make Iceberg "not just files":
partitioning, row-level MERGE upserts, and safe schema evolution. Builds
demo.de.events_clean and exercises each with assertions. Backs data-engineer
lab-04 (partitioning + upserts) and lab-02 (schema evolution); the table it leaves
behind is what the time-travel step queries from Trino.

    docker compose exec spark spark-submit /home/iceberg/jobs/iceberg_features.py
"""
from pyspark.sql import SparkSession

T = "demo.de.events_clean"


def main() -> None:
    spark = SparkSession.builder.appName("iceberg-features").getOrCreate()
    spark.sql("CREATE NAMESPACE IF NOT EXISTS demo.de")
    spark.sql(f"DROP TABLE IF EXISTS {T}")

    # 1) Partitioning — Iceberg hidden partitioning by `kind` (no extra column).
    spark.sql(
        f"""
        CREATE TABLE {T} (id BIGINT, kind STRING, ts TIMESTAMP)
        USING iceberg PARTITIONED BY (kind)
        """
    )
    spark.sql(
        f"""
        INSERT INTO {T} VALUES
          (1, 'click',    TIMESTAMP '2026-06-01 10:00:00'),
          (2, 'view',     TIMESTAMP '2026-06-01 10:01:30'),
          (4, 'purchase', TIMESTAMP '2026-06-01 10:05:00')
        """
    )
    assert spark.table(T).count() == 3
    print("[iceberg] partitioned table created (PARTITIONED BY kind): 3 rows")

    # 2) MERGE upsert — update an existing row, insert a new one in one statement.
    spark.sql(
        f"""
        MERGE INTO {T} t USING (
            SELECT 4 AS id, 'refund' AS kind, TIMESTAMP '2026-06-01 11:00:00' AS ts
            UNION ALL
            SELECT 5,       'click',          TIMESTAMP '2026-06-01 11:05:00'
        ) src
        ON t.id = src.id
        WHEN MATCHED THEN UPDATE SET t.kind = src.kind
        WHEN NOT MATCHED THEN INSERT *
        """
    )
    rows = {r["id"]: r["kind"] for r in spark.sql(f"SELECT id, kind FROM {T}").collect()}
    assert rows.get(4) == "refund" and 5 in rows and len(rows) == 4, rows
    print(f"[iceberg] MERGE upsert: id=4 updated -> refund, id=5 inserted ({rows})")

    # 3) Schema evolution — add a column to a live table, no rewrite.
    spark.sql(f"ALTER TABLE {T} ADD COLUMN amount DOUBLE")
    spark.sql(
        f"INSERT INTO {T} VALUES (6, 'purchase', TIMESTAMP '2026-06-01 12:00:00', 99.5)"
    )
    assert "amount" in spark.table(T).columns
    amount = spark.sql(f"SELECT amount FROM {T} WHERE id = 6").collect()[0]["amount"]
    assert amount == 99.5, amount
    print("[iceberg] schema evolution: added column 'amount', id=6 amount=99.5")

    print(f"[iceberg] OK — partitioning + MERGE upsert + schema evolution on {T}")
    spark.stop()


if __name__ == "__main__":
    main()
