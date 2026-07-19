#!/bin/bash
set -euo pipefail

KAFKA_HOME=/opt/module/kafka
BOOTSTRAP=192.168.10.105:9092

"${KAFKA_HOME}/bin/kafka-topics.sh" \
  --bootstrap-server "${BOOTSTRAP}" \
  --create --if-not-exists \
  --topic bike_trip_raw \
  --partitions 3 \
  --replication-factor 1

"${KAFKA_HOME}/bin/kafka-topics.sh" \
  --bootstrap-server "${BOOTSTRAP}" \
  --describe --topic bike_trip_raw
