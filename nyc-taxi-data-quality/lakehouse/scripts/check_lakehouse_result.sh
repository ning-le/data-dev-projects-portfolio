#!/usr/bin/env bash
set -euo pipefail

source /etc/profile.d/bigdata.sh
ICEBERG_JAR="${ICEBERG_JAR:-/home/atguigu/jars/iceberg-spark-runtime-3.3_2.12-1.6.1.jar}"
SPARK_MASTER="${SPARK_MASTER:-yarn}"

cat > /tmp/nyc_taxi_check.sql <<'SQL'
SET spark.sql.catalog.taxi_catalog=org.apache.iceberg.spark.SparkCatalog;
SET spark.sql.catalog.taxi_catalog.type=hadoop;
SET spark.sql.catalog.taxi_catalog.warehouse=hdfs:///warehouse/nyc_taxi_lake;
USE taxi_catalog.taxi_dw;

SHOW TABLES;

SELECT 'ods_yellow_taxi_trip' AS table_name, COUNT(*) AS cnt FROM ods_yellow_taxi_trip
UNION ALL SELECT 'dim_taxi_zone', COUNT(*) FROM dim_taxi_zone
UNION ALL SELECT 'dwd_taxi_trip_detail', COUNT(*) FROM dwd_taxi_trip_detail
UNION ALL SELECT 'ads_taxi_daily_overview', COUNT(*) FROM ads_taxi_daily_overview
UNION ALL SELECT 'ads_pickup_zone_top10', COUNT(*) FROM ads_pickup_zone_top10
UNION ALL SELECT 'ads_pickup_hour_trend', COUNT(*) FROM ads_pickup_hour_trend
UNION ALL SELECT 'ads_taxi_quality_overview', COUNT(*) FROM ads_taxi_quality_overview
UNION ALL SELECT 'ads_taxi_quality_rule_result', COUNT(*) FROM ads_taxi_quality_rule_result;

SELECT *
FROM ads_taxi_daily_overview
ORDER BY biz_date
LIMIT 10;

SELECT biz_date, rank_no, pickup_borough, pickup_zone, trip_cnt, total_amount, avg_amount
FROM ads_pickup_zone_top10
WHERE biz_date = DATE '2025-01-10'
ORDER BY rank_no
LIMIT 10;

SELECT biz_date, pickup_hour, trip_cnt, total_amount, abnormal_rate
FROM ads_pickup_hour_trend
WHERE biz_date = DATE '2025-01-10'
ORDER BY pickup_hour
LIMIT 24;

SELECT *
FROM ads_taxi_quality_overview
ORDER BY biz_date
LIMIT 10;

SELECT biz_date, rule_name, rule_target, check_status, failed_count, total_count, failed_rate
FROM ads_taxi_quality_rule_result
WHERE biz_date = DATE '2025-01-10'
ORDER BY rule_name, rule_target;
SQL

spark-sql --master "$SPARK_MASTER" --jars "$ICEBERG_JAR" \
  --conf spark.sql.catalog.taxi_catalog=org.apache.iceberg.spark.SparkCatalog \
  --conf spark.sql.catalog.taxi_catalog.type=hadoop \
  --conf spark.sql.catalog.taxi_catalog.warehouse=hdfs:///warehouse/nyc_taxi_lake \
  -f /tmp/nyc_taxi_check.sql
