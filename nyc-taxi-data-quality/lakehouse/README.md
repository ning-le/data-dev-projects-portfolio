# NYC Taxi Offline Lakehouse Module

This module contains the lakehouse pipeline for the NYC Taxi offline analytics project.

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

## Components

- Spark SQL: batch ETL and warehouse layering.
- Iceberg: table format for ODS/DWD/DWS/ADS and partition overwrite backfill.
- HDFS: raw file and Iceberg warehouse storage.
- Trino: direct query engine for Iceberg ADS tables.
- Grafana: business and quality dashboard.

## Main Files

- `sql/00_spark_iceberg_settings.sql`: Spark Iceberg catalog settings.
- `sql/01_ods_iceberg.sql`: raw data loading into Iceberg ODS tables.
- `sql/02_dwd_iceberg.sql`: DIM and DWD processing with quality flags.
- `sql/03_dws_iceberg.sql`: reusable daily, zone, and hourly summaries.
- `sql/04_ads_iceberg.sql`: dashboard business result tables.
- `sql/05_ads_quality_iceberg.sql`: dashboard quality result tables.
- `trino/iceberg.properties`: Trino Iceberg connector configuration.
- `scripts/upload_raw_to_hdfs.sh`: uploads raw files to HDFS.
- `scripts/run_lakehouse_etl.sh`: runs Iceberg ETL, supports full mode and one-date backfill.
- `scripts/start_trino.sh`: starts Trino with the local Java 17 runtime.
- `scripts/check_trino_iceberg_result.sh`: checks Iceberg ADS through Trino.
- `grafana/trino_datasource.json`: Trino datasource definition.
- `grafana/nyc_taxi_lakehouse_trino_dashboard.json`: Trino dashboard definition.
- `grafana/create_grafana_dashboard.sh`: creates the Trino datasource and dashboard.

## Run Modes

Full initialization:

```bash
bash lakehouse/scripts/run_lakehouse_etl.sh
```

One-date backfill:

```bash
bash lakehouse/scripts/run_lakehouse_etl.sh 2025-01-10
```

Check Iceberg through Trino:

```bash
bash lakehouse/scripts/check_trino_iceberg_result.sh 2025-01-10
```
