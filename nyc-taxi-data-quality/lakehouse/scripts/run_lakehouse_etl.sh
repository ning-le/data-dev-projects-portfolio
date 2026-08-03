#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SQL_DIR="$BASE_DIR/sql"

source /etc/profile.d/bigdata.sh

ICEBERG_JAR="${ICEBERG_JAR:-/opt/module/spark/jars/iceberg-spark-runtime.jar}"

COMMON_CONF=(
  --jars "$ICEBERG_JAR"
  --conf spark.sql.catalog.taxi_catalog=org.apache.iceberg.spark.SparkCatalog
  --conf spark.sql.catalog.taxi_catalog.type=hadoop
  --conf spark.sql.catalog.taxi_catalog.warehouse=hdfs:///warehouse/nyc_taxi_lake
  --conf spark.sql.sources.partitionOverwriteMode=dynamic
)

echo "[1/5] Spark Iceberg settings"
spark-sql "${COMMON_CONF[@]}" -f "$SQL_DIR/00_spark_iceberg_settings.sql"

echo "[2/5] Build ODS Iceberg tables"
spark-sql "${COMMON_CONF[@]}" -f "$SQL_DIR/01_ods_iceberg.sql"

echo "[3/5] Build DIM and DWD Iceberg tables"
spark-sql "${COMMON_CONF[@]}" -f "$SQL_DIR/02_dwd_iceberg.sql"

echo "[4/5] Build DWS Iceberg tables"
spark-sql "${COMMON_CONF[@]}" -f "$SQL_DIR/03_dws_iceberg.sql"

echo "[5/5] Build ADS Iceberg tables"
spark-sql "${COMMON_CONF[@]}" -f "$SQL_DIR/04_ads_iceberg.sql"

echo "Lakehouse ETL finished."
