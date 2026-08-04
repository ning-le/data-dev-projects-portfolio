#!/usr/bin/env bash
set -euo pipefail

source /etc/profile.d/bigdata.sh

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICEBERG_JAR="${ICEBERG_JAR:-/home/atguigu/jars/iceberg-spark-runtime-3.3_2.12-1.6.1.jar}"
MYSQL_JAR="${MYSQL_JAR:-/opt/module/spark/jars/mysql-connector-j-8.0.31.jar}"
SPARK_MASTER="${SPARK_MASTER:-local[2]}"

mysql -uroot < "$BASE_DIR/scripts/init_mysql_ads_tables.sql"

spark-sql --master "$SPARK_MASTER" --jars "$ICEBERG_JAR,$MYSQL_JAR"   --conf spark.sql.catalog.taxi_catalog=org.apache.iceberg.spark.SparkCatalog   --conf spark.sql.catalog.taxi_catalog.type=hadoop   --conf spark.sql.catalog.taxi_catalog.warehouse=hdfs:///warehouse/nyc_taxi_lake   -f "$BASE_DIR/sql/06_export_ads_to_mysql.sql"

mysql -uroot nyc_taxi_ads <<'SQL'
SELECT 'ads_taxi_daily_overview' AS table_name, COUNT(*) AS cnt FROM ads_taxi_daily_overview
UNION ALL SELECT 'ads_pickup_zone_top10', COUNT(*) FROM ads_pickup_zone_top10
UNION ALL SELECT 'ads_pickup_hour_trend', COUNT(*) FROM ads_pickup_hour_trend
UNION ALL SELECT 'ads_taxi_quality_overview', COUNT(*) FROM ads_taxi_quality_overview
UNION ALL SELECT 'ads_taxi_quality_rule_result', COUNT(*) FROM ads_taxi_quality_rule_result;
SQL
