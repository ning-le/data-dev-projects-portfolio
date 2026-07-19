USE flight_dw;

CREATE OR REPLACE TEMPORARY VIEW mysql_ads_airline_delay_rank
USING jdbc
OPTIONS (
  url 'jdbc:mysql://localhost:3306/flight_ads?useUnicode=true&characterEncoding=utf8&useSSL=false',
  dbtable 'ads_airline_delay_rank',
  user 'hive',
  password '${MYSQL_PASSWORD}',
  driver 'com.mysql.cj.jdbc.Driver'
);

CREATE OR REPLACE TEMPORARY VIEW mysql_ads_route_delay_topn
USING jdbc
OPTIONS (
  url 'jdbc:mysql://localhost:3306/flight_ads?useUnicode=true&characterEncoding=utf8&useSSL=false',
  dbtable 'ads_route_delay_topn',
  user 'hive',
  password '${MYSQL_PASSWORD}',
  driver 'com.mysql.cj.jdbc.Driver'
);

CREATE OR REPLACE TEMPORARY VIEW mysql_ads_airport_delay_topn
USING jdbc
OPTIONS (
  url 'jdbc:mysql://localhost:3306/flight_ads?useUnicode=true&characterEncoding=utf8&useSSL=false',
  dbtable 'ads_airport_delay_topn',
  user 'hive',
  password '${MYSQL_PASSWORD}',
  driver 'com.mysql.cj.jdbc.Driver'
);

CREATE OR REPLACE TEMPORARY VIEW mysql_ads_hour_delay_trend
USING jdbc
OPTIONS (
  url 'jdbc:mysql://localhost:3306/flight_ads?useUnicode=true&characterEncoding=utf8&useSSL=false',
  dbtable 'ads_hour_delay_trend',
  user 'hive',
  password '${MYSQL_PASSWORD}',
  driver 'com.mysql.cj.jdbc.Driver'
);

INSERT INTO mysql_ads_airline_delay_rank
SELECT
  airline_code,
  airline_name,
  flight_cnt,
  valid_flight_cnt,
  arrival_delay_cnt,
  avg_arrival_delay_min,
  arrival_delay_rate,
  rank_no,
  CAST(flight_date AS DATE)
FROM ads_airline_delay_rank;

INSERT INTO mysql_ads_route_delay_topn
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
  CAST(flight_date AS DATE)
FROM ads_route_delay_topn;

INSERT INTO mysql_ads_airport_delay_topn
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
  CAST(flight_date AS DATE)
FROM ads_airport_delay_topn;

INSERT INTO mysql_ads_hour_delay_trend
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
  CAST(flight_date AS DATE)
FROM ads_hour_delay_trend;
