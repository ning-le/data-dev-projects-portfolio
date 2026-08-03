-- DWD layer: cleaned trip detail table with derived fields.

USE taxi_catalog.taxi_dw;

CREATE TABLE IF NOT EXISTS dim_taxi_zone (
    location_id bigint,
    borough string,
    zone string,
    service_zone string
)
USING iceberg;

CREATE TABLE IF NOT EXISTS dwd_taxi_trip_detail (
    trip_id string,
    vendor_id bigint,
    pickup_time timestamp,
    dropoff_time timestamp,
    biz_date date,
    pickup_hour int,
    pickup_location_id bigint,
    dropoff_location_id bigint,
    pickup_borough string,
    pickup_zone string,
    dropoff_borough string,
    dropoff_zone string,
    passenger_count double,
    trip_distance double,
    trip_duration_sec bigint,
    fare_amount double,
    total_amount double,
    payment_type bigint,
    is_valid_amount int,
    is_valid_distance int,
    is_valid_location int
)
USING iceberg
PARTITIONED BY (biz_date);

INSERT OVERWRITE dim_taxi_zone
SELECT
    LocationID AS location_id,
    Borough AS borough,
    Zone AS zone,
    service_zone
FROM ods_taxi_zone
WHERE LocationID IS NOT NULL;

INSERT OVERWRITE dwd_taxi_trip_detail
SELECT
    md5(concat_ws('|',
        CAST(t.VendorID AS STRING),
        CAST(t.tpep_pickup_datetime AS STRING),
        CAST(t.tpep_dropoff_datetime AS STRING),
        CAST(t.PULocationID AS STRING),
        CAST(t.DOLocationID AS STRING),
        CAST(t.total_amount AS STRING)
    )) AS trip_id,
    t.VendorID AS vendor_id,
    t.tpep_pickup_datetime AS pickup_time,
    t.tpep_dropoff_datetime AS dropoff_time,
    t.biz_date,
    hour(t.tpep_pickup_datetime) AS pickup_hour,
    t.PULocationID AS pickup_location_id,
    t.DOLocationID AS dropoff_location_id,
    pu.borough AS pickup_borough,
    pu.zone AS pickup_zone,
    do_zone.borough AS dropoff_borough,
    do_zone.zone AS dropoff_zone,
    t.passenger_count,
    t.trip_distance,
    CAST(unix_timestamp(t.tpep_dropoff_datetime) - unix_timestamp(t.tpep_pickup_datetime) AS BIGINT) AS trip_duration_sec,
    t.fare_amount,
    t.total_amount,
    t.payment_type,
    CASE WHEN t.fare_amount >= 0 AND t.total_amount >= 0 THEN 1 ELSE 0 END AS is_valid_amount,
    CASE WHEN t.trip_distance >= 0 THEN 1 ELSE 0 END AS is_valid_distance,
    CASE WHEN pu.location_id IS NOT NULL AND do_zone.location_id IS NOT NULL THEN 1 ELSE 0 END AS is_valid_location
FROM ods_yellow_taxi_trip t
LEFT JOIN dim_taxi_zone pu
    ON t.PULocationID = pu.location_id
LEFT JOIN dim_taxi_zone do_zone
    ON t.DOLocationID = do_zone.location_id
WHERE t.tpep_pickup_datetime IS NOT NULL
  AND t.tpep_dropoff_datetime IS NOT NULL
  AND t.biz_date IS NOT NULL;
