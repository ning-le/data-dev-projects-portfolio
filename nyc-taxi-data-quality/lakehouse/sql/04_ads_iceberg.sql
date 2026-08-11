-- ADS layer: simple dashboard result tables.

USE taxi_catalog.taxi_dw;

CREATE TABLE IF NOT EXISTS ads_taxi_daily_overview (
    biz_date date,
    trip_cnt bigint,
    valid_trip_cnt bigint,
    total_amount double,
    avg_amount double,
    avg_distance double,
    avg_duration_sec double,
    abnormal_trip_cnt bigint,
    abnormal_rate double
)
USING iceberg
PARTITIONED BY (biz_date);

CREATE TABLE IF NOT EXISTS ads_pickup_zone_top10 (
    biz_date date,
    pickup_location_id bigint,
    pickup_borough string,
    pickup_zone string,
    trip_cnt bigint,
    total_amount double,
    avg_amount double,
    rank_no int
)
USING iceberg
PARTITIONED BY (biz_date);

CREATE TABLE IF NOT EXISTS ads_pickup_hour_trend (
    biz_date date,
    pickup_hour int,
    trip_cnt bigint,
    valid_trip_cnt bigint,
    total_amount double,
    avg_amount double,
    avg_distance double,
    abnormal_trip_cnt bigint,
    abnormal_rate double
)
USING iceberg
PARTITIONED BY (biz_date);

INSERT OVERWRITE ads_taxi_daily_overview
SELECT
    biz_date,
    trip_cnt,
    valid_trip_cnt,
    total_amount,
    avg_amount,
    avg_distance,
    avg_duration_sec,
    abnormal_trip_cnt,
    CASE
        WHEN trip_cnt = 0 THEN 0
        ELSE ROUND(abnormal_trip_cnt / trip_cnt, 4)
    END AS abnormal_rate
FROM dws_taxi_day_stat
WHERE '${hivevar:biz_date}' = '__ALL__'
   OR biz_date = to_date('${hivevar:biz_date}');

INSERT OVERWRITE ads_pickup_zone_top10
SELECT
    biz_date,
    pickup_location_id,
    pickup_borough,
    pickup_zone,
    trip_cnt,
    total_amount,
    avg_amount,
    rank_no
FROM (
    SELECT
        biz_date,
        pickup_location_id,
        pickup_borough,
        pickup_zone,
        trip_cnt,
        total_amount,
        avg_amount,
        ROW_NUMBER() OVER (
            PARTITION BY biz_date
            ORDER BY trip_cnt DESC, total_amount DESC, pickup_location_id ASC
        ) AS rank_no
    FROM dws_pickup_zone_day_stat
    WHERE pickup_location_id IS NOT NULL
      AND (
          '${hivevar:biz_date}' = '__ALL__'
          OR biz_date = to_date('${hivevar:biz_date}')
      )
) t
WHERE rank_no <= 10;

INSERT OVERWRITE ads_pickup_hour_trend
SELECT
    biz_date,
    pickup_hour,
    trip_cnt,
    valid_trip_cnt,
    total_amount,
    avg_amount,
    avg_distance,
    abnormal_trip_cnt,
    CASE
        WHEN trip_cnt = 0 THEN 0
        ELSE ROUND(abnormal_trip_cnt / trip_cnt, 4)
    END AS abnormal_rate
FROM dws_pickup_hour_stat
WHERE '${hivevar:biz_date}' = '__ALL__'
   OR biz_date = to_date('${hivevar:biz_date}');
