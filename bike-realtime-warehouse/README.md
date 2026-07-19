# Bike Realtime Warehouse

## Background

This project builds a small realtime warehouse for shared bike trips. Source trip events are replayed into Kafka, processed by Flink SQL, written to Doris, and displayed in Grafana.

## Data Flow

```text
CSV/JSONL trip data
-> Python replay script
-> Kafka topic: bike_trip_raw
-> Flink SQL event-time processing
-> Doris DWD and ADS tables
-> Grafana dashboard
```

## Main Files

- `scripts/replay_bike_trip_rt.py`: one-time event replay to Kafka.
- `scripts/replay_bike_trip_rt_live.py`: continuous replay service for dashboard refresh.
- `scripts/create_bike_topics.sh`: creates Kafka topics.
- `sql/bike_rt_base.sql`: Flink SQL source and sink table definitions.
- `sql/bike_rt_job.sql`: Flink SQL realtime insert jobs.
- `sql/bike_rt_run.sql`: full Flink SQL job script.
- `doris/init_bike_rt_doris.py`: initializes Doris database and tables.
- `grafana/doris_bike_dashboard.json`: Grafana dashboard JSON.
- `services/bike-live-replay.service`: systemd service example for continuous replay.

## Metrics

- Trip count per 1 minute
- UV per 1 minute
- Average ride duration
- Start grid heat per 5 minutes
- End grid heat per 5 minutes

## Implementation Notes

- Event time is parsed from `event_time`.
- Watermark is set to 30 seconds in Flink SQL.
- Doris uses `UNIQUE KEY` with Merge On Write for realtime updates.
- The live replay script shifts historical events to current time while keeping event order.
