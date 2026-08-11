-- DWS layer: reusable daily and zone-level summary tables.

USE taxi_catalog.taxi_dw;

CREATE TABLE IF NOT EXISTS dws_taxi_day_stat (
    biz_date date,
    trip_cnt bigint,
    valid_trip_cnt bigint,
    total_amount double,
    avg_amount double,
    avg_distance double,
    avg_duration_sec double,
    abnormal_trip_cnt bigint
)
USING iceberg
PARTITIONED BY (biz_date);

CREATE TABLE IF NOT EXISTS dws_pickup_zone_day_stat (
    biz_date date,
    pickup_location_id bigint,
    pickup_borough string,
    pickup_zone string,
    trip_cnt bigint,
    total_amount double,
    avg_amount double
)
USING iceberg
PARTITIONED BY (biz_date);

CREATE TABLE IF NOT EXISTS dws_pickup_hour_stat (
    biz_date date,
    pickup_hour int,
    trip_cnt bigint,
    valid_trip_cnt bigint,
    total_amount double,
    avg_amount double,
    avg_distance double,
    abnormal_trip_cnt bigint
)
USING iceberg
PARTITIONED BY (biz_date);

INSERT OVERWRITE dws_taxi_day_stat
SELECT
    biz_date,
    COUNT(*) AS trip_cnt,
    SUM(CASE WHEN is_valid_amount = 1 AND is_valid_distance = 1 AND is_valid_location = 1 THEN 1 ELSE 0 END) AS valid_trip_cnt,
    ROUND(SUM(total_amount), 2) AS total_amount,
    ROUND(AVG(total_amount), 2) AS avg_amount,
    ROUND(AVG(trip_distance), 2) AS avg_distance,
    ROUND(AVG(trip_duration_sec), 2) AS avg_duration_sec,
    SUM(CASE WHEN is_valid_amount = 0 OR is_valid_distance = 0 OR is_valid_location = 0 THEN 1 ELSE 0 END) AS abnormal_trip_cnt
FROM dwd_taxi_trip_detail
WHERE '${hivevar:biz_date}' = '__ALL__'
   OR biz_date = to_date('${hivevar:biz_date}')
GROUP BY biz_date;

INSERT OVERWRITE dws_pickup_zone_day_stat
SELECT
    biz_date,
    pickup_location_id,
    pickup_borough,
    pickup_zone,
    COUNT(*) AS trip_cnt,
    ROUND(SUM(total_amount), 2) AS total_amount,
    ROUND(AVG(total_amount), 2) AS avg_amount
FROM dwd_taxi_trip_detail
WHERE pickup_location_id IS NOT NULL
  AND (
      '${hivevar:biz_date}' = '__ALL__'
      OR biz_date = to_date('${hivevar:biz_date}')
  )
GROUP BY
    biz_date,
    pickup_location_id,
    pickup_borough,
    pickup_zone;

INSERT OVERWRITE dws_pickup_hour_stat
SELECT
    biz_date,
    pickup_hour,
    COUNT(*) AS trip_cnt,
    SUM(CASE WHEN is_valid_amount = 1 AND is_valid_distance = 1 AND is_valid_location = 1 THEN 1 ELSE 0 END) AS valid_trip_cnt,
    ROUND(SUM(total_amount), 2) AS total_amount,
    ROUND(AVG(total_amount), 2) AS avg_amount,
    ROUND(AVG(trip_distance), 2) AS avg_distance,
    SUM(CASE WHEN is_valid_amount = 0 OR is_valid_distance = 0 OR is_valid_location = 0 THEN 1 ELSE 0 END) AS abnormal_trip_cnt
FROM dwd_taxi_trip_detail
WHERE pickup_hour IS NOT NULL
  AND (
      '${hivevar:biz_date}' = '__ALL__'
      OR biz_date = to_date('${hivevar:biz_date}')
  )
GROUP BY biz_date, pickup_hour;
