#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SQL_DIR="$BASE_DIR/sql"

source /etc/profile.d/bigdata.sh

ICEBERG_JAR="${ICEBERG_JAR:-/home/atguigu/jars/iceberg-spark-runtime-3.3_2.12-1.6.1.jar}"
SPARK_MASTER="${SPARK_MASTER:-yarn}"
BIZ_DATE="${1:-__ALL__}"

if [[ "$BIZ_DATE" != "__ALL__" && ! "$BIZ_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Usage: $0 [yyyy-MM-dd]" >&2
  exit 1
fi

COMMON_CONF=(
  --master "$SPARK_MASTER"
  --jars "$ICEBERG_JAR"
  --conf spark.sql.catalog.taxi_catalog=org.apache.iceberg.spark.SparkCatalog
  --conf spark.sql.catalog.taxi_catalog.type=hive
  --conf spark.sql.catalog.taxi_catalog.uri=thrift://spark101:9083
  --conf spark.sql.catalog.taxi_catalog.warehouse=hdfs:///warehouse/nyc_taxi_lake/iceberg_warehouse
  --conf spark.sql.sources.partitionOverwriteMode=dynamic
)

run_sql() {
  local sql_file="$1"
  spark-sql "${COMMON_CONF[@]}" --hivevar "biz_date=$BIZ_DATE" -f "$sql_file"
}

echo "Lakehouse ETL mode: biz_date=$BIZ_DATE"

echo "[1/6] Spark Iceberg settings"
run_sql "$SQL_DIR/00_spark_iceberg_settings.sql"

echo "[2/6] Build ODS Iceberg tables"
run_sql "$SQL_DIR/01_ods_iceberg.sql"

echo "[3/6] Build DIM and DWD Iceberg tables"
run_sql "$SQL_DIR/02_dwd_iceberg.sql"

echo "[4/6] Build DWS Iceberg tables"
run_sql "$SQL_DIR/03_dws_iceberg.sql"

echo "[5/6] Build ADS business Iceberg tables"
run_sql "$SQL_DIR/04_ads_iceberg.sql"

echo "[6/6] Build ADS quality Iceberg tables"
run_sql "$SQL_DIR/05_ads_quality_iceberg.sql"
echo "Lakehouse ETL finished. Grafana reads Iceberg ADS directly through Trino."
