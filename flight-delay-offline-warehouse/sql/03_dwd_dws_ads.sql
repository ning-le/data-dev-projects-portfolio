USE flight_dw;
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;
SET spark.sql.shuffle.partitions=4;

DROP TABLE IF EXISTS dwd_flight_detail;
CREATE EXTERNAL TABLE dwd_flight_detail (
    airline_code string,
    flight_number string,
    tail_number string,
    origin_airport string,
    destination_airport string,
    route_code string,
    day_of_week int,
    scheduled_departure int,
    scheduled_departure_hour int,
    departure_time int,
    departure_delay int,
    taxi_out int,
    wheels_off int,
    scheduled_time int,
    elapsed_time int,
    air_time int,
    distance int,
    distance_level string,
    wheels_on int,
    taxi_in int,
    scheduled_arrival int,
    arrival_time int,
    arrival_delay int,
    is_departure_delayed int,
    is_arrival_delayed int,
    is_cancelled int,
    is_diverted int,
    cancellation_reason string,
    air_system_delay int,
    security_delay int,
    airline_delay int,
    late_aircraft_delay int,
    weather_delay int
)
PARTITIONED BY (flight_date string)
STORED AS PARQUET
LOCATION '/warehouse/flight_dw/dwd/dwd_flight_detail';

INSERT OVERWRITE TABLE dwd_flight_detail PARTITION (flight_date)
SELECT
    airline AS airline_code,
    flight_number,
    tail_number,
    origin_airport,
    destination_airport,
    concat_ws('-', origin_airport, destination_airport) AS route_code,
    CAST(day_of_week AS INT) AS day_of_week,
    CAST(scheduled_departure AS INT) AS scheduled_departure,
    CASE
        WHEN CAST(substr(lpad(scheduled_departure, 4, '0'), 1, 2) AS INT) = 24 THEN 0
        ELSE CAST(substr(lpad(scheduled_departure, 4, '0'), 1, 2) AS INT)
    END AS scheduled_departure_hour,
    CAST(departure_time AS INT) AS departure_time,
    CAST(departure_delay AS INT) AS departure_delay,
    CAST(taxi_out AS INT) AS taxi_out,
    CAST(wheels_off AS INT) AS wheels_off,
    CAST(scheduled_time AS INT) AS scheduled_time,
    CAST(elapsed_time AS INT) AS elapsed_time,
    CAST(air_time AS INT) AS air_time,
    CAST(distance AS INT) AS distance,
    CASE
        WHEN CAST(distance AS INT) < 500 THEN 'short'
        WHEN CAST(distance AS INT) < 1500 THEN 'medium'
        WHEN CAST(distance AS INT) >= 1500 THEN 'long'
        ELSE 'unknown'
    END AS distance_level,
    CAST(wheels_on AS INT) AS wheels_on,
    CAST(taxi_in AS INT) AS taxi_in,
    CAST(scheduled_arrival AS INT) AS scheduled_arrival,
    CAST(arrival_time AS INT) AS arrival_time,
    CAST(arrival_delay AS INT) AS arrival_delay,
    CASE WHEN CAST(departure_delay AS INT) > 0 THEN 1 ELSE 0 END AS is_departure_delayed,
    CASE WHEN CAST(arrival_delay AS INT) > 0 THEN 1 ELSE 0 END AS is_arrival_delayed,
    CAST(cancelled AS INT) AS is_cancelled,
    CAST(diverted AS INT) AS is_diverted,
    cancellation_reason,
    CAST(air_system_delay AS INT) AS air_system_delay,
    CAST(security_delay AS INT) AS security_delay,
    CAST(airline_delay AS INT) AS airline_delay,
    CAST(late_aircraft_delay AS INT) AS late_aircraft_delay,
    CAST(weather_delay AS INT) AS weather_delay,
    date_format(
        to_date(concat_ws('-', year, lpad(month, 2, '0'), lpad(day, 2, '0'))),
        'yyyy-MM-dd'
    ) AS flight_date
FROM ods_flight_info
WHERE year IS NOT NULL
  AND month IS NOT NULL
  AND day IS NOT NULL
  AND airline IS NOT NULL
  AND origin_airport IS NOT NULL
  AND destination_airport IS NOT NULL;

DROP TABLE IF EXISTS dws_airline_day_stat;
CREATE EXTERNAL TABLE dws_airline_day_stat (
    airline_code string,
    airline_name string,
    flight_cnt bigint,
    valid_flight_cnt bigint,
    cancelled_cnt bigint,
    diverted_cnt bigint,
    departure_delay_cnt bigint,
    arrival_delay_cnt bigint,
    avg_departure_delay_min decimal(16,2),
    avg_arrival_delay_min decimal(16,2),
    departure_delay_rate decimal(16,4),
    arrival_delay_rate decimal(16,4),
    cancel_rate decimal(16,4)
)
PARTITIONED BY (flight_date string)
STORED AS PARQUET
LOCATION '/warehouse/flight_dw/dws/dws_airline_day_stat';

INSERT OVERWRITE TABLE dws_airline_day_stat PARTITION (flight_date)
SELECT
    dwd.airline_code,
    dim.airline_name,
    COUNT(*) AS flight_cnt,
    SUM(CASE WHEN dwd.is_cancelled = 0 AND dwd.is_diverted = 0 THEN 1 ELSE 0 END) AS valid_flight_cnt,
    SUM(dwd.is_cancelled) AS cancelled_cnt,
    SUM(dwd.is_diverted) AS diverted_cnt,
    SUM(dwd.is_departure_delayed) AS departure_delay_cnt,
    SUM(dwd.is_arrival_delayed) AS arrival_delay_cnt,
    ROUND(AVG(CASE WHEN dwd.departure_delay IS NOT NULL THEN dwd.departure_delay ELSE NULL END), 2) AS avg_departure_delay_min,
    ROUND(AVG(CASE WHEN dwd.arrival_delay IS NOT NULL THEN dwd.arrival_delay ELSE NULL END), 2) AS avg_arrival_delay_min,
    ROUND(
        SUM(dwd.is_departure_delayed) /
        NULLIF(SUM(CASE WHEN dwd.is_cancelled = 0 AND dwd.is_diverted = 0 THEN 1 ELSE 0 END), 0),
        4
    ) AS departure_delay_rate,
    ROUND(
        SUM(dwd.is_arrival_delayed) /
        NULLIF(SUM(CASE WHEN dwd.is_cancelled = 0 AND dwd.is_diverted = 0 THEN 1 ELSE 0 END), 0),
        4
    ) AS arrival_delay_rate,
    ROUND(SUM(dwd.is_cancelled) / COUNT(*), 4) AS cancel_rate,
    dwd.flight_date
FROM dwd_flight_detail dwd
LEFT JOIN dim_airline_info dim
    ON dwd.airline_code = dim.airline_code
GROUP BY
    dwd.airline_code,
    dim.airline_name,
    dwd.flight_date;

DROP TABLE IF EXISTS dws_route_day_stat;
CREATE EXTERNAL TABLE dws_route_day_stat (
    route_code string,
    origin_airport string,
    destination_airport string,
    flight_cnt bigint,
    valid_flight_cnt bigint,
    arrival_delay_cnt bigint,
    avg_arrival_delay_min decimal(16,2),
    arrival_delay_rate decimal(16,4),
    avg_distance decimal(16,2)
)
PARTITIONED BY (flight_date string)
STORED AS PARQUET
LOCATION '/warehouse/flight_dw/dws/dws_route_day_stat';

INSERT OVERWRITE TABLE dws_route_day_stat PARTITION (flight_date)
SELECT
    route_code,
    origin_airport,
    destination_airport,
    COUNT(*) AS flight_cnt,
    SUM(CASE WHEN is_cancelled = 0 AND is_diverted = 0 THEN 1 ELSE 0 END) AS valid_flight_cnt,
    SUM(is_arrival_delayed) AS arrival_delay_cnt,
    ROUND(AVG(arrival_delay), 2) AS avg_arrival_delay_min,
    ROUND(
        SUM(is_arrival_delayed) /
        NULLIF(SUM(CASE WHEN is_cancelled = 0 AND is_diverted = 0 THEN 1 ELSE 0 END), 0),
        4
    ) AS arrival_delay_rate,
    ROUND(AVG(distance), 2) AS avg_distance,
    flight_date
FROM dwd_flight_detail
GROUP BY
    route_code,
    origin_airport,
    destination_airport,
    flight_date;

DROP TABLE IF EXISTS dws_airport_day_stat;
CREATE EXTERNAL TABLE dws_airport_day_stat (
    airport_code string,
    airport_name string,
    city string,
    state string,
    flight_cnt bigint,
    valid_flight_cnt bigint,
    departure_delay_cnt bigint,
    avg_departure_delay_min decimal(16,2),
    departure_delay_rate decimal(16,4)
)
PARTITIONED BY (flight_date string)
STORED AS PARQUET
LOCATION '/warehouse/flight_dw/dws/dws_airport_day_stat';

INSERT OVERWRITE TABLE dws_airport_day_stat PARTITION (flight_date)
SELECT
    dwd.origin_airport AS airport_code,
    dim.airport_name,
    dim.city,
    dim.state,
    COUNT(*) AS flight_cnt,
    SUM(CASE WHEN dwd.is_cancelled = 0 AND dwd.is_diverted = 0 THEN 1 ELSE 0 END) AS valid_flight_cnt,
    SUM(dwd.is_departure_delayed) AS departure_delay_cnt,
    ROUND(AVG(dwd.departure_delay), 2) AS avg_departure_delay_min,
    ROUND(
        SUM(dwd.is_departure_delayed) /
        NULLIF(SUM(CASE WHEN dwd.is_cancelled = 0 AND dwd.is_diverted = 0 THEN 1 ELSE 0 END), 0),
        4
    ) AS departure_delay_rate,
    dwd.flight_date
FROM dwd_flight_detail dwd
LEFT JOIN dim_airport_info dim
    ON dwd.origin_airport = dim.airport_code
GROUP BY
    dwd.origin_airport,
    dim.airport_name,
    dim.city,
    dim.state,
    dwd.flight_date;

DROP TABLE IF EXISTS dws_hour_day_stat;
CREATE EXTERNAL TABLE dws_hour_day_stat (
    scheduled_departure_hour int,
    flight_cnt bigint,
    valid_flight_cnt bigint,
    departure_delay_cnt bigint,
    arrival_delay_cnt bigint,
    avg_departure_delay_min decimal(16,2),
    avg_arrival_delay_min decimal(16,2),
    departure_delay_rate decimal(16,4),
    arrival_delay_rate decimal(16,4)
)
PARTITIONED BY (flight_date string)
STORED AS PARQUET
LOCATION '/warehouse/flight_dw/dws/dws_hour_day_stat';

INSERT OVERWRITE TABLE dws_hour_day_stat PARTITION (flight_date)
SELECT
    scheduled_departure_hour,
    COUNT(*) AS flight_cnt,
    SUM(CASE WHEN is_cancelled = 0 AND is_diverted = 0 THEN 1 ELSE 0 END) AS valid_flight_cnt,
    SUM(is_departure_delayed) AS departure_delay_cnt,
    SUM(is_arrival_delayed) AS arrival_delay_cnt,
    ROUND(AVG(departure_delay), 2) AS avg_departure_delay_min,
    ROUND(AVG(arrival_delay), 2) AS avg_arrival_delay_min,
    ROUND(
        SUM(is_departure_delayed) /
        NULLIF(SUM(CASE WHEN is_cancelled = 0 AND is_diverted = 0 THEN 1 ELSE 0 END), 0),
        4
    ) AS departure_delay_rate,
    ROUND(
        SUM(is_arrival_delayed) /
        NULLIF(SUM(CASE WHEN is_cancelled = 0 AND is_diverted = 0 THEN 1 ELSE 0 END), 0),
        4
    ) AS arrival_delay_rate,
    flight_date
FROM dwd_flight_detail
GROUP BY
    scheduled_departure_hour,
    flight_date;

DROP TABLE IF EXISTS ads_airline_delay_rank;
CREATE EXTERNAL TABLE ads_airline_delay_rank (
    airline_code string,
    airline_name string,
    flight_cnt bigint,
    valid_flight_cnt bigint,
    arrival_delay_cnt bigint,
    avg_arrival_delay_min decimal(16,2),
    arrival_delay_rate decimal(16,4),
    rank_no int
)
PARTITIONED BY (flight_date string)
STORED AS PARQUET
LOCATION '/warehouse/flight_dw/ads/ads_airline_delay_rank';

INSERT OVERWRITE TABLE ads_airline_delay_rank PARTITION (flight_date)
SELECT
    airline_code,
    airline_name,
    flight_cnt,
    valid_flight_cnt,
    arrival_delay_cnt,
    avg_arrival_delay_min,
    arrival_delay_rate,
    rank_no,
    flight_date
FROM (
    SELECT
        airline_code,
        airline_name,
        flight_cnt,
        valid_flight_cnt,
        arrival_delay_cnt,
        avg_arrival_delay_min,
        arrival_delay_rate,
        flight_date,
        ROW_NUMBER() OVER (
            PARTITION BY flight_date
            ORDER BY arrival_delay_rate DESC, arrival_delay_cnt DESC, flight_cnt DESC, airline_code ASC
        ) AS rank_no
    FROM dws_airline_day_stat
    WHERE valid_flight_cnt > 0
) t
WHERE rank_no <= 10;

DROP TABLE IF EXISTS ads_route_delay_topn;
CREATE EXTERNAL TABLE ads_route_delay_topn (
    route_code string,
    origin_airport string,
    destination_airport string,
    flight_cnt bigint,
    valid_flight_cnt bigint,
    arrival_delay_cnt bigint,
    avg_arrival_delay_min decimal(16,2),
    arrival_delay_rate decimal(16,4),
    rank_no int
)
PARTITIONED BY (flight_date string)
STORED AS PARQUET
LOCATION '/warehouse/flight_dw/ads/ads_route_delay_topn';

INSERT OVERWRITE TABLE ads_route_delay_topn PARTITION (flight_date)
SELECT
    route_code,
    origin_airport,
    destination_airport,
    flight_cnt,
    valid_flight_cnt,
    arrival_delay_cnt,
    avg_arrival_delay_min,
    arrival_delay_rate,
    rank_no,
    flight_date
FROM (
    SELECT
        route_code,
        origin_airport,
        destination_airport,
        flight_cnt,
        valid_flight_cnt,
        arrival_delay_cnt,
        avg_arrival_delay_min,
        arrival_delay_rate,
        flight_date,
        ROW_NUMBER() OVER (
            PARTITION BY flight_date
            ORDER BY arrival_delay_rate DESC, arrival_delay_cnt DESC, flight_cnt DESC, route_code ASC
        ) AS rank_no
    FROM dws_route_day_stat
    WHERE valid_flight_cnt >= 5
) t
WHERE rank_no <= 10;

DROP TABLE IF EXISTS ads_airport_delay_topn;
CREATE EXTERNAL TABLE ads_airport_delay_topn (
    airport_code string,
    airport_name string,
    city string,
    state string,
    flight_cnt bigint,
    valid_flight_cnt bigint,
    departure_delay_cnt bigint,
    avg_departure_delay_min decimal(16,2),
    departure_delay_rate decimal(16,4),
    rank_no int
)
PARTITIONED BY (flight_date string)
STORED AS PARQUET
LOCATION '/warehouse/flight_dw/ads/ads_airport_delay_topn';

INSERT OVERWRITE TABLE ads_airport_delay_topn PARTITION (flight_date)
SELECT
    airport_code,
    airport_name,
    city,
    state,
    flight_cnt,
    valid_flight_cnt,
    departure_delay_cnt,
    avg_departure_delay_min,
    departure_delay_rate,
    rank_no,
    flight_date
FROM (
    SELECT
        airport_code,
        airport_name,
        city,
        state,
        flight_cnt,
        valid_flight_cnt,
        departure_delay_cnt,
        avg_departure_delay_min,
        departure_delay_rate,
        flight_date,
        ROW_NUMBER() OVER (
            PARTITION BY flight_date
            ORDER BY departure_delay_rate DESC, departure_delay_cnt DESC, flight_cnt DESC, airport_code ASC
        ) AS rank_no
    FROM dws_airport_day_stat
    WHERE valid_flight_cnt >= 5
) t
WHERE rank_no <= 10;

DROP TABLE IF EXISTS ads_hour_delay_trend;
CREATE EXTERNAL TABLE ads_hour_delay_trend (
    scheduled_departure_hour int,
    flight_cnt bigint,
    valid_flight_cnt bigint,
    departure_delay_cnt bigint,
    arrival_delay_cnt bigint,
    avg_departure_delay_min decimal(16,2),
    avg_arrival_delay_min decimal(16,2),
    departure_delay_rate decimal(16,4),
    arrival_delay_rate decimal(16,4)
)
PARTITIONED BY (flight_date string)
STORED AS PARQUET
LOCATION '/warehouse/flight_dw/ads/ads_hour_delay_trend';

INSERT OVERWRITE TABLE ads_hour_delay_trend PARTITION (flight_date)
SELECT
    scheduled_departure_hour,
    flight_cnt,
    valid_flight_cnt,
    departure_delay_cnt,
    arrival_delay_cnt,
    avg_departure_delay_min,
    avg_arrival_delay_min,
    departure_delay_rate,
    arrival_delay_rate,
    flight_date
FROM dws_hour_day_stat;

SELECT 'dim_airline_info' AS table_name, COUNT(*) AS cnt FROM dim_airline_info
UNION ALL
SELECT 'dim_airport_info' AS table_name, COUNT(*) AS cnt FROM dim_airport_info
UNION ALL
SELECT 'dwd_flight_detail' AS table_name, COUNT(*) AS cnt FROM dwd_flight_detail
UNION ALL
SELECT 'dws_airline_day_stat' AS table_name, COUNT(*) AS cnt FROM dws_airline_day_stat
UNION ALL
SELECT 'dws_route_day_stat' AS table_name, COUNT(*) AS cnt FROM dws_route_day_stat
UNION ALL
SELECT 'dws_airport_day_stat' AS table_name, COUNT(*) AS cnt FROM dws_airport_day_stat
UNION ALL
SELECT 'dws_hour_day_stat' AS table_name, COUNT(*) AS cnt FROM dws_hour_day_stat
UNION ALL
SELECT 'ads_airline_delay_rank' AS table_name, COUNT(*) AS cnt FROM ads_airline_delay_rank
UNION ALL
SELECT 'ads_route_delay_topn' AS table_name, COUNT(*) AS cnt FROM ads_route_delay_topn
UNION ALL
SELECT 'ads_airport_delay_topn' AS table_name, COUNT(*) AS cnt FROM ads_airport_delay_topn
UNION ALL
SELECT 'ads_hour_delay_trend' AS table_name, COUNT(*) AS cnt FROM ads_hour_delay_trend;
