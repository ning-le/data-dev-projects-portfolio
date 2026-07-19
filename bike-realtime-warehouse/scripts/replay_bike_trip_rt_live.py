import argparse
import hashlib
import json
import time
from datetime import datetime, timedelta
from pathlib import Path

from kafka import KafkaProducer


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bootstrap-servers", default="192.168.10.105:9092")
    parser.add_argument("--topic", default="bike_trip_raw")
    parser.add_argument(
        "--input",
        default="/home/atguigu/project/bike_rt_kraft_doris/data/citibike_trip_events.jsonl",
    )
    parser.add_argument(
        "--speedup",
        type=float,
        default=60.0,
        help="Replay speed multiplier. 60 means 1 hour of source data is replayed in 1 minute.",
    )
    parser.add_argument(
        "--pause-seconds",
        type=float,
        default=5.0,
        help="Pause between completed replay cycles.",
    )
    return parser.parse_args()


def load_events(path: Path) -> list[dict]:
    rows = []
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            obj = json.loads(line)
            obj["_event_dt"] = datetime.strptime(obj["event_time"], "%Y-%m-%d %H:%M:%S")
            rows.append(obj)
    rows.sort(key=lambda item: item["_event_dt"])
    return rows


def shifted_event(event: dict, cycle_no: int, shifted_event_time: datetime) -> dict:
    ride_duration_sec = int(event["ride_duration_sec"])
    start_time = shifted_event_time
    end_time = shifted_event_time + timedelta(seconds=ride_duration_sec)
    raw = f'{event["trip_id"]}|{cycle_no}|{shifted_event_time.isoformat()}'
    trip_id = hashlib.md5(raw.encode("utf-8")).hexdigest()
    return {
        "trip_id": trip_id,
        "company_id": event["company_id"],
        "user_id": event["user_id"],
        "start_time": start_time.strftime("%Y-%m-%d %H:%M:%S"),
        "end_time": end_time.strftime("%Y-%m-%d %H:%M:%S"),
        "event_time": shifted_event_time.strftime("%Y-%m-%d %H:%M:%S"),
        "start_lng": event["start_lng"],
        "start_lat": event["start_lat"],
        "end_lng": event["end_lng"],
        "end_lat": event["end_lat"],
        "ride_duration_sec": ride_duration_sec,
        "start_grid": event["start_grid"],
        "end_grid": event["end_grid"],
        "coord_sys": event["coord_sys"],
        "event_date": shifted_event_time.strftime("%Y-%m-%d"),
    }


def main() -> None:
    args = parse_args()
    events = load_events(Path(args.input))
    base_start = events[0]["_event_dt"]

    producer = KafkaProducer(
        bootstrap_servers=args.bootstrap_servers,
        value_serializer=lambda item: json.dumps(item, ensure_ascii=False).encode("utf-8"),
    )

    cycle_no = 0
    try:
        while True:
            cycle_anchor = datetime.now().replace(microsecond=0)
            wall_clock_anchor = time.time()
            sent = 0
            for event in events:
                source_offset = (event["_event_dt"] - base_start).total_seconds()
                replay_offset = source_offset / max(args.speedup, 1.0)
                due_at = wall_clock_anchor + replay_offset
                sleep_for = due_at - time.time()
                if sleep_for > 0:
                    time.sleep(sleep_for)
                shifted_time = cycle_anchor + timedelta(seconds=replay_offset)
                payload = shifted_event(event, cycle_no, shifted_time)
                producer.send(args.topic, payload)
                sent += 1
                if sent % 1000 == 0:
                    producer.flush()
                    print(f"cycle={cycle_no} sent={sent}")
            producer.flush()
            print(f"cycle={cycle_no} completed, sent={sent}")
            cycle_no += 1
            time.sleep(max(args.pause_seconds, 0.0))
    finally:
        producer.flush()
        producer.close()


if __name__ == "__main__":
    main()
