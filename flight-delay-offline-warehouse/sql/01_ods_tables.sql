CREATE DATABASE IF NOT EXISTS flight_dw;
USE flight_dw;

DROP TABLE IF EXISTS ods_flight_info;
CREATE EXTERNAL TABLE ods_flight_info (
    year string,
    month string,
    day string,
    day_of_week string,
    airline string,
    flight_number string,
    tail_number string,
    origin_airport string,
    destination_airport string,
    scheduled_departure string,
    departure_time string,
    departure_delay string,
    taxi_out string,
    wheels_off string,
    scheduled_time string,
    elapsed_time string,
    air_time string,
    distance string,
    wheels_on string,
    taxi_in string,
    scheduled_arrival string,
    arrival_time string,
    arrival_delay string,
    diverted string,
    cancelled string,
    cancellation_reason string,
    air_system_delay string,
    security_delay string,
    airline_delay string,
    late_aircraft_delay string,
    weather_delay string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    "separatorChar" = ","
)
STORED AS TEXTFILE
LOCATION '/warehouse/flight_dw/ods/flight_info'
TBLPROPERTIES ("skip.header.line.count"="1");

DROP TABLE IF EXISTS ods_airline_info;
CREATE EXTERNAL TABLE ods_airline_info (
    iata_code string,
    airline_name string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    "separatorChar" = ","
)
STORED AS TEXTFILE
LOCATION '/warehouse/flight_dw/ods/airline_info'
TBLPROPERTIES ("skip.header.line.count"="1");

DROP TABLE IF EXISTS ods_airport_info;
CREATE EXTERNAL TABLE ods_airport_info (
    iata_code string,
    airport_name string,
    city string,
    state string,
    country string,
    latitude string,
    longitude string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    "separatorChar" = ","
)
STORED AS TEXTFILE
LOCATION '/warehouse/flight_dw/ods/airport_info'
TBLPROPERTIES ("skip.header.line.count"="1");
