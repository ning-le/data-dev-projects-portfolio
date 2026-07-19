#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SQL_DIR="$BASE_DIR/sql"

source /etc/profile.d/bigdata.sh

MYSQL_USER="${MYSQL_USER:-hive}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-changeme}"
MYSQL_JAR="$(ls /opt/module/hive/lib/mysql-connector*.jar /opt/module/spark/jars/mysql-connector*.jar 2>/dev/null | head -n 1)"

mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "
USE flight_ads;
TRUNCATE TABLE ads_airline_delay_rank;
TRUNCATE TABLE ads_route_delay_topn;
TRUNCATE TABLE ads_airport_delay_topn;
TRUNCATE TABLE ads_hour_delay_trend;
"

tmp_sql="/tmp/export_ads_to_mysql_$$.sql"
sed "s/\\${MYSQL_PASSWORD}/$MYSQL_PASSWORD/g" "$SQL_DIR/05_export_ads_to_mysql.sql" > "$tmp_sql"
spark-sql --jars "$MYSQL_JAR" -f "$tmp_sql"
rm -f "$tmp_sql"
