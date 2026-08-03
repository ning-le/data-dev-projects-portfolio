# NYC Taxi Lakehouse Analytics

This module upgrades the original NYC Taxi data quality project into a small lakehouse analytics project.

The main goal is taxi operation analysis. Data quality checks are used as a governance module, not as the only business output.

## Data Flow

```text
NYC Taxi raw parquet / taxi zone csv
-> HDFS raw area
-> Spark SQL
-> Iceberg ODS
-> Iceberg DIM / DWD
-> Iceberg DWS
-> Iceberg ADS
-> Trino
-> Grafana
```

Quality flow:

```text
Iceberg ODS/DWD or sample parquet
-> Python + YAML quality rules
-> SQLite task_runs / rule_results
-> Streamlit or Grafana quality dashboard
```

## Components

- Spark SQL: batch ETL and warehouse layering.
- Iceberg: lakehouse table format for ODS/DWD/DWS/ADS.
- HDFS: raw file and Iceberg warehouse storage.
- Trino: SQL query layer for Grafana.
- Grafana: business dashboard.
- Python/YAML/SQLite: lightweight data quality and backfill tracking.

## Tables

ODS:

- `ods_yellow_taxi_trip`
- `ods_taxi_zone`

DIM/DWD:

- `dim_taxi_zone`
- `dwd_taxi_trip_detail`

DWS:

- `dws_taxi_day_stat`
- `dws_pickup_zone_day_stat`
- `dws_pickup_hour_stat`

ADS:

- `ads_taxi_daily_overview`
- `ads_pickup_zone_top10`
- `ads_pickup_hour_trend`

## Business Metrics

- Daily trip count
- Daily total amount
- Average order amount
- Average trip distance
- Average trip duration
- Abnormal trip count and rate
- Pickup zone Top10
- Hourly pickup trend

## Main Files

- `sql/00_spark_iceberg_settings.sql`: Spark Iceberg catalog settings.
- `sql/01_ods_iceberg.sql`: raw data loading into Iceberg ODS tables.
- `sql/02_dwd_iceberg.sql`: DIM and DWD processing.
- `sql/03_dws_iceberg.sql`: reusable summary tables.
- `sql/04_ads_iceberg.sql`: dashboard result tables.
- `scripts/upload_raw_to_hdfs.sh`: uploads raw files to HDFS.
- `scripts/run_lakehouse_etl.sh`: runs all Spark SQL jobs.
- `trino/iceberg.properties`: Trino Iceberg catalog example.
- `trino/dashboard_queries.sql`: SQL examples for Grafana.

## Interview Summary

This project uses Iceberg to manage lakehouse tables and keeps the familiar ODS/DWD/DWS/ADS modeling flow. Spark SQL writes Iceberg tables, Trino queries ADS tables, and Grafana displays simple taxi operation metrics. The original data quality platform remains as a governance module for not-null, non-negative, foreign-key, and row-count fluctuation checks.
