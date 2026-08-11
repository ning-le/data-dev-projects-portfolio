#!/usr/bin/env bash
set -euo pipefail

TRINO_CLI="${TRINO_CLI:-/opt/module/trino/bin/trino-cli.sh}"
CHECK_DATE="${1:-2025-01-10}"

if [[ ! "$CHECK_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Usage: $0 [yyyy-MM-dd]" >&2
  exit 1
fi

cat > /tmp/nyc_taxi_trino_check.sql <<SQL
SHOW TABLES FROM iceberg.taxi_dw;

SELECT 'ads_taxi_daily_overview' AS table_name, COUNT(*) AS cnt FROM iceberg.taxi_dw.ads_taxi_daily_overview
UNION ALL SELECT 'ads_pickup_zone_top10', COUNT(*) FROM iceberg.taxi_dw.ads_pickup_zone_top10
UNION ALL SELECT 'ads_pickup_hour_trend', COUNT(*) FROM iceberg.taxi_dw.ads_pickup_hour_trend
UNION ALL SELECT 'ads_taxi_quality_overview', COUNT(*) FROM iceberg.taxi_dw.ads_taxi_quality_overview
UNION ALL SELECT 'ads_taxi_quality_rule_result', COUNT(*) FROM iceberg.taxi_dw.ads_taxi_quality_rule_result;

SELECT biz_date, trip_cnt, valid_trip_cnt, total_amount, abnormal_rate
FROM iceberg.taxi_dw.ads_taxi_daily_overview
ORDER BY biz_date
LIMIT 10;

SELECT biz_date, pickup_hour, trip_cnt, abnormal_rate
FROM iceberg.taxi_dw.ads_pickup_hour_trend
WHERE biz_date = DATE '$CHECK_DATE'
ORDER BY pickup_hour
LIMIT 24;

SELECT committed_at, snapshot_id, operation
FROM iceberg.taxi_dw."ads_taxi_daily_overview$snapshots"
ORDER BY committed_at DESC
LIMIT 5;
SQL

"$TRINO_CLI" -f /tmp/nyc_taxi_trino_check.sql
