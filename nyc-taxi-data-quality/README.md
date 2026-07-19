# NYC Taxi Data Quality Platform

## Background

This project implements a lightweight data quality and backfill platform for offline ingestion checks. It uses Pandas for rule execution, YAML for task configuration, SQLite for run history, and Streamlit for a simple status page.

## Main Features

- Configurable quality rules in YAML
- Rule types: `not_null`, `non_negative`, `fk_exists`, `row_count_fluctuation`
- Run history stored in SQLite
- Supports `run`, `rerun`, and `backfill`
- Streamlit page for task and rule result review

## Directory

```text
nyc-taxi-data-quality/
|-- app.py
|-- requirements.txt
|-- config/
|   `-- rules.yaml
|-- sample_data/
|   |-- taxi_trips.csv
|   `-- taxi_zones.csv
`-- src/
    `-- quality_engine.py
```

## Run

Install dependencies:

```bash
pip install -r requirements.txt
```

Run one business date:

```bash
python src/quality_engine.py run --task taxi_trips_daily --biz-date 2024-01-01
```

Rerun one business date:

```bash
python src/quality_engine.py rerun --task taxi_trips_daily --biz-date 2024-01-01
```

Backfill a date range:

```bash
python src/quality_engine.py backfill --task taxi_trips_daily --start-date 2024-01-01 --end-date 2024-01-03
```

Start Streamlit:

```bash
streamlit run app.py
```

## Notes

The included CSV files are only small samples. Replace them with NYC TLC trip data and zone dimension data when running with real data.
