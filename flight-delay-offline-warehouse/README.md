# Flight Delay Offline Warehouse

## Background

This project builds an offline warehouse for flight delay analysis. Source CSV files are stored on HDFS and mapped by Hive ODS external tables. Spark SQL is used for DIM, DWD, DWS, and ADS processing. ADS results are exported to MariaDB for Grafana visualization.

## Data Flow

```text
Flight CSV files
-> HDFS
-> Hive ODS external tables
-> Spark SQL DIM/DWD/DWS/ADS
-> MariaDB ADS tables
-> Grafana dashboard
```

## Warehouse Layers

- ODS: raw flight, airline, and airport CSV tables.
- DIM: airline and airport dimension tables.
- DWD: cleaned flight detail table with derived fields.
- DWS: reusable daily summary tables by airline, route, airport, and hour.
- ADS: dashboard tables for ranking, TopN, and trend analysis.

## Main Files

- `sql/01_ods_tables.sql`: creates ODS external tables.
- `sql/02_dim_tables.sql`: creates and loads DIM tables.
- `sql/03_dwd_dws_ads.sql`: creates DWD, DWS, and ADS tables.
- `sql/04_mysql_ads_tables.sql`: creates MariaDB dashboard tables.
- `sql/05_export_ads_to_mysql.sql`: exports Hive ADS tables to MariaDB through Spark SQL JDBC temporary views.
- `scripts/etl_all.sh`: runs ODS, DIM, DWD, DWS, and ADS jobs.
- `scripts/export_ads_to_mysql.sh`: truncates MariaDB ADS tables and exports latest ADS results.
- `grafana/flight_delay_dashboard.json`: Grafana dashboard JSON.

## Main Metrics

- Airline arrival delay Top10
- Route arrival delay TopN
- Airport departure delay Top10
- Hourly departure and arrival delay trend
- Daily flight count
- Daily arrival delay rate

## Implementation Notes

- DWD uses `flight_date` as partition field.
- DWD generates `route_code`, `scheduled_departure_hour`, delay flags, cancel/divert flags, and `distance_level`.
- Spark SQL `INSERT OVERWRITE` is used for offline rerun idempotency.
- MariaDB dashboard tables are truncated before export to avoid duplicate rows.
