package com.gridatek.odp;

import org.apache.spark.sql.SparkSession;

/**
 * A minimal Java Spark application that reads the governed Iceberg table and
 * writes a curated copy through the shared REST catalog — the Java counterpart
 * of the PySpark jobs. The spark-iceberg image's spark-defaults already wires the
 * `demo` catalog to iceberg-rest + MinIO, so the app just uses SQL.
 *
 * Build (JAR):  mvn -q package
 * Submit:       spark-submit --class com.gridatek.odp.IcebergApp app.jar
 */
public class IcebergApp {
    public static void main(String[] args) {
        SparkSession spark = SparkSession.builder()
                .appName("iceberg-java-app")
                .getOrCreate();

        String src = "demo.smoke.events";
        String dst = "demo.de.events_java";

        spark.sql("CREATE NAMESPACE IF NOT EXISTS demo.de");
        spark.sql("CREATE TABLE IF NOT EXISTS " + dst
                + " (id BIGINT, kind STRING) USING iceberg");
        spark.sql("INSERT OVERWRITE " + dst + " SELECT id, kind FROM " + src);

        long rows = spark.table(dst).count();
        System.out.println("[java-app] wrote " + dst + " with " + rows + " rows from " + src);

        spark.stop();
    }
}
