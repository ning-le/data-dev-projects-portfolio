USE flight_dw;
SET spark.sql.shuffle.partitions=4;

DROP TABLE IF EXISTS dim_airline_info;
CREATE EXTERNAL TABLE dim_airline_info (
    airline_code string,
    airline_name string
)
STORED AS PARQUET
LOCATION '/warehouse/flight_dw/dim/dim_airline_info';

INSERT OVERWRITE TABLE dim_airline_info
SELECT
    iata_code AS airline_code,
    airline_name
FROM ods_airline_info
WHERE iata_code IS NOT NULL
  AND iata_code <> '';

DROP TABLE IF EXISTS dim_airport_info;
CREATE EXTERNAL TABLE dim_airport_info (
    airport_code string,
    airport_name string,
    city string,
    state string,
    country string,
    latitude double,
    longitude double
)
STORED AS PARQUET
LOCATION '/warehouse/flight_dw/dim/dim_airport_info';

INSERT OVERWRITE TABLE dim_airport_info
SELECT
    iata_code AS airport_code,
    airport_name,
    city,
    state,
    country,
    CAST(latitude AS DOUBLE) AS latitude,
    CAST(longitude AS DOUBLE) AS longitude
FROM ods_airport_info
WHERE iata_code IS NOT NULL
  AND iata_code <> '';
