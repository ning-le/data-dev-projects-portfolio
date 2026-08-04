# Grafana Panel SQL

Grafana should connect to Trino and query Iceberg ADS tables.

## Daily Core Metrics

```sql
SELECT
    SUM(trip_cnt) AS trip_cnt,
    ROUND(SUM(total_amount), 2) AS total_amount,
    ROUND(SUM(total_amount) / NULLIF(SUM(trip_cnt), 0), 2) AS avg_amount
FROM iceberg.taxi_dw.ads_taxi_daily_overview;
```

## Daily Trip Trend

```sql
SELECT
    biz_date,
    trip_cnt
FROM iceberg.taxi_dw.ads_taxi_daily_overview
ORDER BY biz_date;
```

## Daily Amount Trend

```sql
SELECT
    biz_date,
    total_amount
FROM iceberg.taxi_dw.ads_taxi_daily_overview
ORDER BY biz_date;
```

## Pickup Zone Top10

```sql
SELECT
    rank_no,
    pickup_borough,
    pickup_zone,
    trip_cnt,
    total_amount
FROM iceberg.taxi_dw.ads_pickup_zone_top10
WHERE biz_date = DATE '2025-01-10'
ORDER BY rank_no;
```

## Hourly Pickup Trend

```sql
SELECT
    DATE_ADD(biz_date, INTERVAL pickup_hour HOUR) AS time,
    trip_cnt
FROM ads_pickup_hour_trend
ORDER BY biz_date, pickup_hour;
```

## Abnormal Trip Rate

```sql
SELECT
    biz_date,
    abnormal_rate
FROM iceberg.taxi_dw.ads_taxi_daily_overview
ORDER BY biz_date;
```

## Quality Overview

```sql
SELECT
    biz_date,
    total_trip_cnt,
    valid_trip_cnt,
    invalid_trip_cnt,
    overall_invalid_rate
FROM iceberg.taxi_dw.ads_taxi_quality_overview
ORDER BY biz_date;
```

## Quality Rule Results

```sql
SELECT
    rule_name,
    rule_target,
    check_status,
    failed_count,
    total_count,
    failed_rate
FROM iceberg.taxi_dw.ads_taxi_quality_rule_result
WHERE biz_date = DATE '2025-01-10'
ORDER BY rule_name, rule_target;
```
