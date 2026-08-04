# NYC Taxi Lakehouse Analytics

This module upgrades the original NYC Taxi data quality project into a small lakehouse analytics project.

The main goal is taxi operation analysis with built-in quality monitoring. Business metrics and quality metrics are both produced from Iceberg DWD and exposed through the same ADS layer.

## Data Flow

```text
NYC Taxi raw parquet / taxi zone csv
-> HDFS raw area
-> Spark SQL
-> Iceberg ODS
-> Iceberg DIM / DWD
-> Iceberg DWS
-> Iceberg ADS
-> MariaDB ADS export tables
-> Grafana
```

Quality metrics are generated from the same DWD table:

```text
Iceberg DWD quality flags
-> Iceberg ADS quality tables
-> MariaDB ADS export tables
-> Grafana business + quality dashboard
```

## Components

- Spark SQL: batch ETL and warehouse layering.
- Iceberg: lakehouse table format for ODS/DWD/DWS/ADS.
- HDFS: raw file and Iceberg warehouse storage.
- MariaDB: dashboard serving layer for ADS export tables.
- Grafana: business dashboard.

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
- `ads_taxi_quality_overview`
- `ads_taxi_quality_rule_result`

## Business Metrics

- Daily trip count
- Daily total amount
- Average order amount
- Average trip distance
- Average trip duration
- Abnormal trip count and rate
- Pickup zone Top10
- Hourly pickup trend
- Quality invalid count and rate
- Quality rule result by business date

## Main Files

- `sql/00_spark_iceberg_settings.sql`: Spark Iceberg catalog settings.
- `sql/01_ods_iceberg.sql`: raw data loading into Iceberg ODS tables.
- `sql/02_dwd_iceberg.sql`: DIM and DWD processing.
- `sql/03_dws_iceberg.sql`: reusable summary tables.
- `sql/04_ads_iceberg.sql`: dashboard result tables.
- `sql/05_ads_quality_iceberg.sql`: dashboard-ready quality result tables.
- `sql/06_export_ads_to_mysql.sql`: Spark SQL JDBC export from Iceberg ADS to MariaDB.
- `scripts/upload_raw_to_hdfs.sh`: uploads raw files to HDFS.
- `scripts/run_lakehouse_etl.sh`: runs all Spark SQL jobs.
- `scripts/export_ads_to_mysql.sh`: exports ADS tables to MariaDB.
- `trino/iceberg.properties`: Trino Iceberg catalog example.
- `trino/dashboard_queries.sql`: SQL examples for Grafana.
- `grafana/create_grafana_dashboard.sh`: creates the Grafana datasource and dashboard.

## Interview Summary

This project uses Iceberg to manage lakehouse tables and keeps the familiar ODS/DWD/DWS/ADS modeling flow. Spark SQL writes Iceberg tables, DWD adds quality flags, ADS produces both operation metrics and quality-monitoring metrics, and Grafana displays them in the same dashboard through MariaDB ADS export tables.
