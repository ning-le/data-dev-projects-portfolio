# NYC Taxi Data Quality Platform

A lightweight data quality and backfill platform based on NYC TLC yellow taxi trip data.

## Background

In an offline warehouse pipeline, source data should be checked before it is loaded into downstream DWD/DWS/ADS jobs. This project simulates that process with configurable quality rules, task execution history, rerun, backfill, and a Streamlit monitoring page.

## Stack

- Python
- Pandas
- SQLite
- Streamlit
- YAML

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
- Support normal run, historical rerun, and date-range backfill.
- Provide a Streamlit dashboard for run status and failed rule analysis.

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
