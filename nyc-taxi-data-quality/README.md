# NYC Taxi Lakehouse Analytics

A lightweight lakehouse analytics project based on NYC TLC yellow taxi trip data.

## Background

This project builds an offline lakehouse pipeline for taxi operation analysis. It uses Spark SQL to process raw NYC Taxi files on HDFS, stores layered warehouse tables with Iceberg, and exports ADS result tables to MariaDB for Grafana visualization.

Data quality is not a separate Python task anymore. The DWD layer adds quality flags, and the ADS layer produces quality-monitoring result tables from those flags. Business metrics and quality metrics are displayed from the same Iceberg ADS layer.

## Stack

- Spark SQL
- Iceberg
- HDFS
- MariaDB
- Grafana

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
|   |   |-- 05_ads_quality_iceberg.sql
|   |   `-- 06_export_ads_to_mysql.sql
|   |-- scripts/
|   |   |-- upload_raw_to_hdfs.sh
|   |   |-- run_lakehouse_etl.sh
|   |   |-- check_lakehouse_result.sh
|   |   |-- init_mysql_ads_tables.sql
|   |   `-- export_ads_to_mysql.sh
|   |-- trino/
|   |   |-- iceberg.properties
|   |   `-- dashboard_queries.sql
|   `-- grafana/
|       |-- panel_sql.md
|       |-- mysql_datasource.json
|       |-- nyc_taxi_lakehouse_dashboard.json
|       `-- create_grafana_dashboard.sh
`-- README.md
```

## Data Flow

```text
NYC Taxi raw parquet / taxi zone csv
-> HDFS raw area
-> Spark SQL
-> Iceberg ODS
-> Iceberg DIM / DWD
-> Iceberg DWS
-> Iceberg ADS business tables + quality tables
-> MariaDB ADS export tables
-> Grafana
```

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

## Metrics

Business metrics:

- Daily trip count
- Daily total amount
- Average order amount
- Average trip distance
- Average trip duration
- Pickup zone Top10
- Hourly pickup trend

Quality metrics:

- Invalid trip count
- Invalid amount count and rate
- Invalid distance count and rate
- Invalid location count and rate
- Quality rule status by business date

## Commands

Upload raw files to HDFS:

```bash
cd /home/atguigu/project/nyc-taxi-data-quality
bash lakehouse/scripts/upload_raw_to_hdfs.sh
```

Run the full lakehouse ETL:

```bash
cd /home/atguigu/project/nyc-taxi-data-quality
export ICEBERG_JAR=/home/atguigu/jars/iceberg-spark-runtime-3.3_2.12-1.6.1.jar
bash lakehouse/scripts/run_lakehouse_etl.sh
```

Check ADS results:

```bash
cd /home/atguigu/project/nyc-taxi-data-quality
bash lakehouse/scripts/check_lakehouse_result.sh
```

Export ADS tables to MariaDB:

```bash
cd /home/atguigu/project/nyc-taxi-data-quality
SPARK_MASTER=local[2] bash lakehouse/scripts/export_ads_to_mysql.sh
```

Create Grafana datasource and dashboard:

```bash
cd /home/atguigu/project/nyc-taxi-data-quality
bash lakehouse/grafana/create_grafana_dashboard.sh
```

## Interview Summary

This project uses Spark SQL and Iceberg to build an ODS/DWD/DWS/ADS lakehouse pipeline. DWD keeps cleaned taxi trip details and adds quality flags for amount, distance, and location validity. DWS builds reusable daily, zone, and hourly summaries. ADS produces both business dashboard tables and quality-monitoring tables. The ADS tables are exported to MariaDB, and Grafana uses the MySQL datasource to display operation metrics and quality metrics in the same dashboard.
