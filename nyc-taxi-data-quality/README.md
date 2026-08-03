# NYC Taxi Lakehouse Analytics + Quality Platform

A lightweight lakehouse analytics and data quality platform based on NYC TLC yellow taxi trip data.

## Background

This project has two layers of output from the same taxi data chain:

- Lakehouse analytics: build ODS/DWD/DWS/ADS tables with Spark SQL and Iceberg, then query ADS results through Trino/Grafana.
- Quality monitoring: produce invalid-count, invalid-rate, and rule-result ADS tables from DWD quality flags.

The main business scenario is taxi operation analysis. Data quality is integrated into the same Iceberg ADS layer, so Grafana can show business metrics and quality metrics together.

## Stack

- Python
- Pandas
- SQLite
- Streamlit
- YAML
- Spark SQL
- Iceberg
- HDFS
- Trino
- Grafana

## Project Structure

```text
nyc-taxi-data-quality/
|-- app/
|   |-- cli.py
|   |-- config/loader.py
|   |-- core/checks.py
|   |-- core/runner.py
|   `-- db/
|       |-- db_utils.py
|       `-- init_db.py
|-- configs/
|   |-- rules.yaml
|   `-- tasks.yaml
|-- data/sample/
|   |-- yellow_tripdata_sample.parquet
|   `-- taxi_zone_lookup.csv
|-- lakehouse/
|   |-- sql/
|   |-- scripts/
|   |-- trino/
|   `-- grafana/
|-- scripts/make_sample.py
|-- ui/dashboard.py
`-- requirements.txt
```

## Features

- Configure check tasks in `configs/tasks.yaml`.
- Configure rule types and rule targets in `configs/rules.yaml`.
- Support `not_null`, `non_negative`, `fk_exists`, and `row_count_fluctuation`.
- Store task-level run records in SQLite table `task_runs`.
- Store rule-level check results in SQLite table `rule_results`.
- Store latest task result in SQLite table `task_run_latest`.
- Store latest rule result in SQLite table `rule_result_latest`.
- Support normal run, historical rerun, and date-range backfill.
- Provide a Streamlit dashboard for run status and failed rule analysis.
- Provide an Iceberg lakehouse extension for taxi trip analysis.

## Lakehouse Extension

Data flow:

```text
NYC Taxi raw parquet / taxi zone csv
-> HDFS raw area
-> Spark SQL
-> Iceberg ODS / DIM / DWD / DWS / ADS
-> Trino
-> Grafana
```

Main tables:

- ODS: `ods_yellow_taxi_trip`, `ods_taxi_zone`
- DIM/DWD: `dim_taxi_zone`, `dwd_taxi_trip_detail`
- DWS: `dws_taxi_day_stat`, `dws_pickup_zone_day_stat`, `dws_pickup_hour_stat`
- ADS: `ads_taxi_daily_overview`, `ads_pickup_zone_top10`, `ads_pickup_hour_trend`, `ads_taxi_quality_overview`, `ads_taxi_quality_rule_result`

Main metrics:

- Daily trip count
- Daily total amount
- Average order amount
- Average trip distance
- Average trip duration
- Abnormal trip count and rate
- Pickup zone Top10
- Hourly pickup trend
- Quality invalid count/rate
- Quality rule result by business date

Lakehouse files:

- `lakehouse/sql/01_ods_iceberg.sql`: load raw files into Iceberg ODS tables.
- `lakehouse/sql/02_dwd_iceberg.sql`: build DIM and DWD cleaned detail table.
- `lakehouse/sql/03_dws_iceberg.sql`: build reusable summary tables.
- `lakehouse/sql/04_ads_iceberg.sql`: build dashboard result tables.
- `lakehouse/sql/05_ads_quality_iceberg.sql`: build quality result tables from DWD flags.
- `lakehouse/scripts/run_lakehouse_etl.sh`: run the full Spark SQL ETL chain.
- `lakehouse/trino/dashboard_queries.sql`: Grafana panel SQL examples.

## Commands

Initialize the SQLite metadata database:

```bash
python -m app.cli init
```

Run one business date:

```bash
python -m app.cli run yellow_taxi_daily_check 2025-01-10
```

List recent runs:

```bash
python -m app.cli list-runs --limit 10
```

Rerun one historical run:

```bash
python -m app.cli rerun 1
```

Backfill a date range:

```bash
python -m app.cli backfill yellow_taxi_daily_check 2025-01-10 2025-01-20
```

Start the dashboard:

```bash
streamlit run ui/dashboard.py
```

## Interview Summary

This project is mainly used to explain data quality in offline data development. The core idea is to define quality rules with YAML, execute checks with Pandas, persist run history and failed rule details in SQLite, and support rerun/backfill when historical data needs to be repaired.
