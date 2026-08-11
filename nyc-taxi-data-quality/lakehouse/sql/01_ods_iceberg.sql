-- ODS layer: load raw NYC Taxi parquet and taxi zone csv into Iceberg tables.
-- Raw files expected on HDFS:
--   /warehouse/nyc_taxi_lake/raw/yellow_tripdata_2025-01.parquet
--   /warehouse/nyc_taxi_lake/raw/taxi_zone_lookup.csv

USE taxi_catalog.taxi_dw;

CREATE TABLE IF NOT EXISTS ods_yellow_taxi_trip (
    VendorID bigint,
    tpep_pickup_datetime timestamp,
    tpep_dropoff_datetime timestamp,
    passenger_count double,
    trip_distance double,
    RatecodeID double,
    store_and_fwd_flag string,
    PULocationID bigint,
    DOLocationID bigint,
    payment_type bigint,
    fare_amount double,
    extra double,
    mta_tax double,
    tip_amount double,
    tolls_amount double,
    improvement_surcharge double,
    total_amount double,
    congestion_surcharge double,
    Airport_fee double,
    cbd_congestion_fee double,
    biz_date date
)
USING iceberg
PARTITIONED BY (biz_date);

CREATE TABLE IF NOT EXISTS ods_taxi_zone (
    LocationID bigint,
    Borough string,
    Zone string,
    service_zone string
)
USING iceberg;

CREATE OR REPLACE TEMPORARY VIEW raw_yellow_taxi_trip
USING parquet
OPTIONS (
    path '/warehouse/nyc_taxi_lake/raw/yellow_tripdata_2025-01.parquet'
);

CREATE OR REPLACE TEMPORARY VIEW raw_taxi_zone
USING csv
OPTIONS (
    path '/warehouse/nyc_taxi_lake/raw/taxi_zone_lookup.csv',
    header 'true',
    inferSchema 'true'
);

INSERT OVERWRITE ods_yellow_taxi_trip
SELECT
    VendorID,
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    passenger_count,
    trip_distance,
    RatecodeID,
    store_and_fwd_flag,
    PULocationID,
    DOLocationID,
    payment_type,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    Airport_fee,
    cbd_congestion_fee,
    CAST(tpep_pickup_datetime AS DATE) AS biz_date
FROM raw_yellow_taxi_trip
WHERE tpep_pickup_datetime IS NOT NULL
  AND (
      '${hivevar:biz_date}' = '__ALL__'
      OR CAST(tpep_pickup_datetime AS DATE) = to_date('${hivevar:biz_date}')
  );

INSERT OVERWRITE ods_taxi_zone
SELECT
    CAST(LocationID AS BIGINT) AS LocationID,
    Borough,
    Zone,
    service_zone
FROM raw_taxi_zone
WHERE LocationID IS NOT NULL;
