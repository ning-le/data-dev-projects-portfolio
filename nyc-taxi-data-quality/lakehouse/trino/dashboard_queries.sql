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

-- Daily quality overview from the same Iceberg ADS layer.
SELECT
    biz_date,
    total_trip_cnt,
    valid_trip_cnt,
    invalid_trip_cnt,
    invalid_amount_cnt,
    invalid_distance_cnt,
    invalid_location_cnt,
    overall_invalid_rate
FROM iceberg.taxi_dw.ads_taxi_quality_overview
ORDER BY biz_date;

-- Quality rule result for one business date.
SELECT
    biz_date,
    rule_name,
    rule_target,
    check_status,
    failed_count,
    total_count,
    failed_rate,
    expected_value
FROM iceberg.taxi_dw.ads_taxi_quality_rule_result
WHERE biz_date = DATE '2025-01-10'
ORDER BY rule_name, rule_target;
