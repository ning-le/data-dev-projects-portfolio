-- Spark SQL session settings for the NYC Taxi Iceberg lakehouse.
-- Adjust warehouse path if the cluster uses MinIO/S3 instead of HDFS.

SET spark.sql.catalog.taxi_catalog=org.apache.iceberg.spark.SparkCatalog;
SET spark.sql.catalog.taxi_catalog.type=hive;
SET spark.sql.catalog.taxi_catalog.uri=thrift://spark101:9083;
SET spark.sql.catalog.taxi_catalog.warehouse=hdfs:///warehouse/nyc_taxi_lake/iceberg_warehouse;
SET spark.sql.shuffle.partitions=8;
SET spark.sql.sources.partitionOverwriteMode=dynamic;

CREATE DATABASE IF NOT EXISTS taxi_catalog.taxi_dw;
