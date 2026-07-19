import argparse
import json
import time
from datetime import datetime
from pathlib import Path

from kafka import KafkaProducer


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bootstrap-servers", default="192.168.10.105:9092")
    parser.add_argument("--topic", default="bike_trip_raw")
    parser.add_argument("--input", default="/home/atguigu/project/bike_rt_kraft_doris/data/citibike_trip_events.jsonl")
    parser.add_argument("--speedup", type=float, default=600.0)
    parser.add_argument("--limit", type=int, default=0)
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


def main() -> None:
    args = parse_args()
    events = load_events(Path(args.input))
    if args.limit > 0:
        events = events[: args.limit]

    producer = KafkaProducer(
        bootstrap_servers=args.bootstrap_servers,
        value_serializer=lambda item: json.dumps(item, ensure_ascii=False).encode("utf-8"),
    )

    last_dt = None
    sent = 0
    for event in events:
        event_dt = event.pop("_event_dt")
        if last_dt is not None:
            delay = (event_dt - last_dt).total_seconds() / max(args.speedup, 1.0)
            if delay > 0:
                time.sleep(min(delay, 2.0))
        producer.send(args.topic, event)
        sent += 1
        last_dt = event_dt
        if sent % 1000 == 0:
            producer.flush()
            print(f"sent={sent}")

    producer.flush()
    producer.close()
    print(f"done, sent={sent}, topic={args.topic}")


if __name__ == "__main__":
    main()
