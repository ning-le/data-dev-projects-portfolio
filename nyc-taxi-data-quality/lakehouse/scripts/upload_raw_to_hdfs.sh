#!/usr/bin/env bash
set -euo pipefail

RAW_DIR="${RAW_DIR:-/warehouse/nyc_taxi_lake/raw}"
LOCAL_TRIP_FILE="${LOCAL_TRIP_FILE:-/home/atguigu/nyc_taxi_data/yellow_tripdata_2025-01.parquet}"
LOCAL_ZONE_FILE="${LOCAL_ZONE_FILE:-/home/atguigu/nyc_taxi_data/taxi_zone_lookup.csv}"

source /etc/profile.d/bigdata.sh

hdfs dfs -mkdir -p "$RAW_DIR"
hdfs dfs -put -f "$LOCAL_TRIP_FILE" "$RAW_DIR/yellow_tripdata_2025-01.parquet"
hdfs dfs -put -f "$LOCAL_ZONE_FILE" "$RAW_DIR/taxi_zone_lookup.csv"

hdfs dfs -ls -h "$RAW_DIR"
