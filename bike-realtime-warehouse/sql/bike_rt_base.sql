SET 'execution.checkpointing.interval' = '10 s';
SET 'parallelism.default' = '1';
SET 'table.exec.state.ttl' = '30 min';

CREATE TABLE bike_trip_raw_src (
  trip_id STRING,
  company_id STRING,
  user_id STRING,
  start_time STRING,
  end_time STRING,
  event_time STRING,
  start_lng DOUBLE,
  start_lat DOUBLE,
  end_lng DOUBLE,
  end_lat DOUBLE,
  ride_duration_sec INT,
  start_grid STRING,
  end_grid STRING,
  coord_sys STRING,
  event_date STRING,
  rt AS TO_TIMESTAMP(event_time),
  WATERMARK FOR rt AS rt - INTERVAL '30' SECOND
) WITH (
  'connector' = 'kafka',
  'topic' = 'bike_trip_raw',
  'properties.bootstrap.servers' = '192.168.10.105:9092',
  'properties.group.id' = 'flink-bike-rt-v1',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'json',
  'json.ignore-parse-errors' = 'true'
);

CREATE TABLE dwd_bike_trip_rt_doris (
  trip_id STRING,
  company_id STRING,
  user_id STRING,
  start_time TIMESTAMP(3),
  end_time TIMESTAMP(3),
  event_time TIMESTAMP(3),
  start_lng DOUBLE,
  start_lat DOUBLE,
  end_lng DOUBLE,
  end_lat DOUBLE,
  ride_duration_sec INT,
  start_grid STRING,
  end_grid STRING,
  coord_sys STRING,
  event_date DATE
) WITH (
  'connector' = 'doris',
  'fenodes' = '192.168.10.105:8030',
  'jdbc-url' = 'jdbc:mysql://192.168.10.105:9030',
  'table.identifier' = 'bike_rt.dwd_bike_trip_rt',
  'username' = 'root',
  'password' = '',
  'sink.label-prefix' = 'bike_dwd',
  'sink.enable-2pc' = 'false'
);

CREATE TABLE ads_bike_trip_cnt_1m_doris (
  window_start TIMESTAMP(3),
  window_end TIMESTAMP(3),
  trip_cnt BIGINT,
  uv BIGINT,
  avg_duration_sec DOUBLE
) WITH (
  'connector' = 'doris',
  'fenodes' = '192.168.10.105:8030',
  'jdbc-url' = 'jdbc:mysql://192.168.10.105:9030',
  'table.identifier' = 'bike_rt.ads_bike_trip_cnt_1m',
  'username' = 'root',
  'password' = '',
  'sink.label-prefix' = 'bike_trip_cnt_1m',
  'sink.enable-2pc' = 'false'
);

CREATE TABLE ads_bike_start_heat_5m_doris (
  window_start TIMESTAMP(3),
  window_end TIMESTAMP(3),
  start_grid STRING,
  center_lng DOUBLE,
  center_lat DOUBLE,
  trip_cnt BIGINT,
  uv BIGINT
) WITH (
  'connector' = 'doris',
  'fenodes' = '192.168.10.105:8030',
  'jdbc-url' = 'jdbc:mysql://192.168.10.105:9030',
  'table.identifier' = 'bike_rt.ads_bike_start_heat_5m',
  'username' = 'root',
  'password' = '',
  'sink.label-prefix' = 'bike_start_heat_5m',
  'sink.enable-2pc' = 'false'
);

CREATE TABLE ads_bike_end_heat_5m_doris (
  window_start TIMESTAMP(3),
  window_end TIMESTAMP(3),
  end_grid STRING,
  center_lng DOUBLE,
  center_lat DOUBLE,
  trip_cnt BIGINT,
  uv BIGINT
) WITH (
  'connector' = 'doris',
  'fenodes' = '192.168.10.105:8030',
  'jdbc-url' = 'jdbc:mysql://192.168.10.105:9030',
  'table.identifier' = 'bike_rt.ads_bike_end_heat_5m',
  'username' = 'root',
  'password' = '',
  'sink.label-prefix' = 'bike_end_heat_5m',
  'sink.enable-2pc' = 'false'
);
