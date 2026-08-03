-- ADS quality layer: dashboard-ready data quality results from Iceberg DWD.
-- This keeps quality monitoring in the same lakehouse chain as business metrics.

USE taxi_catalog.taxi_dw;

CREATE TABLE IF NOT EXISTS ads_taxi_quality_overview (
    biz_date date,
    total_trip_cnt bigint,
    valid_trip_cnt bigint,
    invalid_trip_cnt bigint,
    invalid_amount_cnt bigint,
    invalid_distance_cnt bigint,
    invalid_location_cnt bigint,
    invalid_amount_rate double,
    invalid_distance_rate double,
    invalid_location_rate double,
    overall_invalid_rate double
)
USING iceberg
PARTITIONED BY (biz_date);

CREATE TABLE IF NOT EXISTS ads_taxi_quality_rule_result (
    biz_date date,
    rule_name string,
    rule_target string,
    check_status string,
    failed_count bigint,
    total_count bigint,
    failed_rate double,
    expected_value string
)
USING iceberg
PARTITIONED BY (biz_date);

INSERT OVERWRITE ads_taxi_quality_overview
SELECT
    biz_date,
    COUNT(*) AS total_trip_cnt,
    SUM(CASE WHEN is_valid_amount = 1 AND is_valid_distance = 1 AND is_valid_location = 1 THEN 1 ELSE 0 END) AS valid_trip_cnt,
    SUM(CASE WHEN is_valid_amount = 0 OR is_valid_distance = 0 OR is_valid_location = 0 THEN 1 ELSE 0 END) AS invalid_trip_cnt,
    SUM(CASE WHEN is_valid_amount = 0 THEN 1 ELSE 0 END) AS invalid_amount_cnt,
    SUM(CASE WHEN is_valid_distance = 0 THEN 1 ELSE 0 END) AS invalid_distance_cnt,
    SUM(CASE WHEN is_valid_location = 0 THEN 1 ELSE 0 END) AS invalid_location_cnt,
    CASE WHEN COUNT(*) = 0 THEN 0 ELSE ROUND(SUM(CASE WHEN is_valid_amount = 0 THEN 1 ELSE 0 END) / COUNT(*), 4) END AS invalid_amount_rate,
    CASE WHEN COUNT(*) = 0 THEN 0 ELSE ROUND(SUM(CASE WHEN is_valid_distance = 0 THEN 1 ELSE 0 END) / COUNT(*), 4) END AS invalid_distance_rate,
    CASE WHEN COUNT(*) = 0 THEN 0 ELSE ROUND(SUM(CASE WHEN is_valid_location = 0 THEN 1 ELSE 0 END) / COUNT(*), 4) END AS invalid_location_rate,
    CASE WHEN COUNT(*) = 0 THEN 0 ELSE ROUND(SUM(CASE WHEN is_valid_amount = 0 OR is_valid_distance = 0 OR is_valid_location = 0 THEN 1 ELSE 0 END) / COUNT(*), 4) END AS overall_invalid_rate
FROM dwd_taxi_trip_detail
GROUP BY biz_date;

INSERT OVERWRITE ads_taxi_quality_rule_result
SELECT
    biz_date,
    rule_name,
    rule_target,
    CASE WHEN failed_count = 0 THEN 'passed' ELSE 'failed' END AS check_status,
    failed_count,
    total_count,
    CASE WHEN total_count = 0 THEN 0 ELSE ROUND(failed_count / total_count, 4) END AS failed_rate,
    expected_value
FROM (
    SELECT
        biz_date,
        'non_negative' AS rule_name,
        'fare_amount,total_amount' AS rule_target,
        SUM(CASE WHEN is_valid_amount = 0 THEN 1 ELSE 0 END) AS failed_count,
        COUNT(*) AS total_count,
        'fare_amount >= 0 and total_amount >= 0' AS expected_value
    FROM dwd_taxi_trip_detail
    GROUP BY biz_date

    UNION ALL

    SELECT
        biz_date,
        'non_negative' AS rule_name,
        'trip_distance' AS rule_target,
        SUM(CASE WHEN is_valid_distance = 0 THEN 1 ELSE 0 END) AS failed_count,
        COUNT(*) AS total_count,
        'trip_distance >= 0' AS expected_value
    FROM dwd_taxi_trip_detail
    GROUP BY biz_date

    UNION ALL

    SELECT
        biz_date,
        'fk_exists' AS rule_name,
        'PULocationID,DOLocationID' AS rule_target,
        SUM(CASE WHEN is_valid_location = 0 THEN 1 ELSE 0 END) AS failed_count,
        COUNT(*) AS total_count,
        'pickup and dropoff location exist in dim_taxi_zone' AS expected_value
    FROM dwd_taxi_trip_detail
    GROUP BY biz_date
) t;
