EXECUTE STATEMENT SET
BEGIN

INSERT INTO dwd_bike_trip_rt_doris
SELECT
  trip_id,
  company_id,
  user_id,
  TO_TIMESTAMP(start_time),
  TO_TIMESTAMP(end_time),
  TO_TIMESTAMP(event_time),
  start_lng,
  start_lat,
  end_lng,
  end_lat,
  ride_duration_sec,
  start_grid,
  end_grid,
  coord_sys,
  CAST(event_date AS DATE)
FROM bike_trip_raw_src;

INSERT INTO ads_bike_trip_cnt_1m_doris
SELECT
  window_start,
  window_end,
  COUNT(*) AS trip_cnt,
  COUNT(DISTINCT user_id) AS uv,
  AVG(CAST(ride_duration_sec AS DOUBLE)) AS avg_duration_sec
FROM TABLE(
  TUMBLE(TABLE bike_trip_raw_src, DESCRIPTOR(rt), INTERVAL '1' MINUTE)
)
GROUP BY window_start, window_end;

INSERT INTO ads_bike_start_heat_5m_doris
SELECT
  window_start,
  window_end,
  start_grid,
  AVG(start_lng) AS center_lng,
  AVG(start_lat) AS center_lat,
  COUNT(*) AS trip_cnt,
  COUNT(DISTINCT user_id) AS uv
FROM TABLE(
  TUMBLE(TABLE bike_trip_raw_src, DESCRIPTOR(rt), INTERVAL '5' MINUTE)
)
GROUP BY window_start, window_end, start_grid;

INSERT INTO ads_bike_end_heat_5m_doris
SELECT
  window_start,
  window_end,
  end_grid,
  AVG(end_lng) AS center_lng,
  AVG(end_lat) AS center_lat,
  COUNT(*) AS trip_cnt,
  COUNT(DISTINCT user_id) AS uv
FROM TABLE(
  TUMBLE(TABLE bike_trip_raw_src, DESCRIPTOR(rt), INTERVAL '5' MINUTE)
)
GROUP BY window_start, window_end, end_grid;

END;
