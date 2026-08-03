-- Grafana can use these SQL statements through Trino.

-- Daily overview cards and trend.
SELECT
    biz_date,
    trip_cnt,
    valid_trip_cnt,
    total_amount,
    avg_amount,
    avg_distance,
    avg_duration_sec,
    abnormal_trip_cnt,
    abnormal_rate
FROM iceberg.taxi_dw.ads_taxi_daily_overview
ORDER BY biz_date;

-- Pickup zone Top10 for one business date.
SELECT
    biz_date,
    rank_no,
    pickup_borough,
    pickup_zone,
    trip_cnt,
    total_amount,
    avg_amount
FROM iceberg.taxi_dw.ads_pickup_zone_top10
WHERE biz_date = DATE '2025-01-10'
ORDER BY rank_no;

-- Hourly pickup trend for one business date.
SELECT
    biz_date,
    pickup_hour,
    trip_cnt,
    total_amount,
    avg_amount,
    abnormal_rate
FROM iceberg.taxi_dw.ads_pickup_hour_trend
WHERE biz_date = DATE '2025-01-10'
ORDER BY pickup_hour;

-- Latest quality failed rules if quality results are exported to SQL database.
-- SELECT task_name, biz_date, rule_type, rule_target, actual_value, expected_value, message
-- FROM rule_result_latest
-- WHERE status = 'failed'
-- ORDER BY biz_date DESC;
