# Data Development Projects Portfolio

This repository contains three data development practice projects used for resume and interview preparation.

## Projects

### 1. Bike Realtime Warehouse

Stack: Kafka KRaft, Flink SQL, Doris, Grafana, Python

Builds a realtime analysis pipeline for shared bike trip data. The project includes data replay to Kafka, Flink SQL event-time aggregation, Doris DWD/ADS table design, and Grafana dashboard configuration.

Main outputs:

- 1-minute trip count and UV trend
- 5-minute start/end grid heat metrics
- DWD trip detail table in Doris
- ADS realtime aggregation tables in Doris

Directory: `bike-realtime-warehouse/`

### 2. Flight Delay Offline Warehouse

Stack: Spark SQL, Hive, HDFS, YARN, MariaDB, Grafana

Builds an offline warehouse based on flight operation, airline, and airport data. The warehouse follows ODS, DIM, DWD, DWS, and ADS layers. ADS results are exported to MariaDB and displayed in Grafana.

Main outputs:

- Airline arrival delay ranking
- Route delay TopN
- Airport departure delay TopN
- Hourly delay trend

Directory: `flight-delay-offline-warehouse/`

### 3. NYC Taxi Data Quality Platform

Stack: Python, Pandas, SQLite, Streamlit, YAML

Implements a lightweight data quality and backfill platform for offline ingestion checks. It supports configurable rules, run history, rerun, and backfill examples.

Main checks:

- not_null
- non_negative
- fk_exists
- row_count_fluctuation

Directory: `nyc-taxi-data-quality/`

## Notes

Large source data files, virtual machine images, component installation packages, and runtime logs are not included. The repository keeps SQL, scripts, configuration examples, and dashboard JSON files only.
