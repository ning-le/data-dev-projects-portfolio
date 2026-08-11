# NYC Taxi Offline Lakehouse Analytics

An offline lakehouse analytics project based on NYC TLC yellow taxi trip data.

## Background

This project builds a Spark SQL and Iceberg based offline lakehouse pipeline for taxi operation analysis. It supports layered data processing, business-date backfill, direct Trino reads from Iceberg, data quality monitoring, and Grafana dashboard visualization.

## Stack

- Spark SQL
- Iceberg
- HDFS
- Trino
- Grafana

## Data Flow

```text
NYC Taxi raw parquet / taxi zone csv
-> HDFS raw area
-> Spark SQL
-> Iceberg ODS
-> Iceberg DIM / DWD
-> Iceberg DWS
-> Iceberg ADS business tables + quality tables
-> Trino
-> Grafana
```

## Project Structure

```text
nyc-taxi-data-quality/
|-- lakehouse/
|   |-- sql/
|   |   |-- 00_spark_iceberg_settings.sql
|   |   |-- 01_ods_iceberg.sql
|   |   |-- 02_dwd_iceberg.sql
|   |   |-- 03_dws_iceberg.sql
|   |   |-- 04_ads_iceberg.sql
|   |   `-- 05_ads_quality_iceberg.sql
|   |-- scripts/
|   |   |-- upload_raw_to_hdfs.sh
|   |   |-- run_lakehouse_etl.sh
|   |   |-- check_trino_iceberg_result.sh
|   |   `-- start_trino.sh
|   `-- grafana/
|       |-- panel_sql_trino.md
|       |-- trino_datasource.json
|       |-- nyc_taxi_lakehouse_trino_dashboard.json
|       `-- create_grafana_dashboard.sh
`-- README.md
```

## Tables

- `ods_yellow_taxi_trip`
- `ods_taxi_zone`
- `dim_taxi_zone`
- `dwd_taxi_trip_detail`
- `dws_taxi_day_stat`
- `dws_pickup_zone_day_stat`
- `dws_pickup_hour_stat`
- `ads_taxi_daily_overview`
- `ads_pickup_zone_top10`
- `ads_pickup_hour_trend`
- `ads_taxi_quality_overview`
- `ads_taxi_quality_rule_result`

## DWD Processing

`dwd_taxi_trip_detail` keeps cleaned trip details and derives:

- `trip_id`: MD5 key generated from vendor, pickup time, dropoff time, pickup location, dropoff location, and total amount.
- `biz_date`: business date extracted from pickup time.
- `pickup_hour`: pickup hour for hourly trend.
- `trip_duration_sec`: dropoff timestamp minus pickup timestamp.
- `is_valid_amount`: whether `fare_amount` and `total_amount` are non-negative.
- `is_valid_distance`: whether `trip_distance` is non-negative.
- `is_valid_location`: whether pickup and dropoff location IDs exist in `dim_taxi_zone`.

## Run Modes

Full initialization:

```bash
bash lakehouse/scripts/run_lakehouse_etl.sh
```

Business-date backfill:

```bash
bash lakehouse/scripts/run_lakehouse_etl.sh 2025-01-10
```

Check Iceberg through Trino:

```bash
bash lakehouse/scripts/check_trino_iceberg_result.sh 2025-01-10
```

## Interview Summary

This project builds an ODS-DWD-DWS-ADS offline lakehouse pipeline with Spark SQL and Iceberg. DWD adds amount, distance, and location quality flags. DWS builds reusable daily, zone, and hourly summaries. ADS produces business dashboard tables and quality-monitoring tables. The pipeline supports full initialization and business-date backfill; Iceberg `INSERT OVERWRITE` rewrites target partitions. Trino reads Iceberg ADS directly for Grafana.
