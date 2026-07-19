#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SQL_DIR="$BASE_DIR/sql"

source /etc/profile.d/bigdata.sh

echo "[1/3] Build ODS tables"
hive -f "$SQL_DIR/01_ods_tables.sql"

echo "[2/3] Build DIM tables"
spark-sql -f "$SQL_DIR/02_dim_tables.sql"

echo "[3/3] Build DWD/DWS/ADS tables"
spark-sql -f "$SQL_DIR/03_dwd_dws_ads.sql"

echo "ETL finished."
