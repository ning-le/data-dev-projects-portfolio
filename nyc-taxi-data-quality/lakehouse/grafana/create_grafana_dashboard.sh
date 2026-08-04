#!/usr/bin/env bash
set -euo pipefail

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-123456}"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

existing=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASSWORD" "$GRAFANA_URL/api/datasources/uid/nyc_taxi_mysql"   | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2 || true)

if [ -n "$existing" ]; then
  curl -s -u "$GRAFANA_USER:$GRAFANA_PASSWORD" -H 'Content-Type: application/json'     -X PUT "$GRAFANA_URL/api/datasources/$existing"     -d @"$BASE_DIR/mysql_datasource.json"
else
  curl -s -u "$GRAFANA_USER:$GRAFANA_PASSWORD" -H 'Content-Type: application/json'     -X POST "$GRAFANA_URL/api/datasources"     -d @"$BASE_DIR/mysql_datasource.json"
fi

echo
curl -s -u "$GRAFANA_USER:$GRAFANA_PASSWORD" -H 'Content-Type: application/json'   -X POST "$GRAFANA_URL/api/dashboards/db"   -d @"$BASE_DIR/nyc_taxi_lakehouse_dashboard.json"
echo
