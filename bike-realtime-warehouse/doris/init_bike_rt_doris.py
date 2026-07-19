import socket
import time

import pymysql


HOST = "192.168.10.105"
PORT = 9030


DDL_LIST = [
    "CREATE DATABASE IF NOT EXISTS bike_rt",
    """
    CREATE TABLE IF NOT EXISTS bike_rt.dwd_bike_trip_rt (
      trip_id VARCHAR(64) NOT NULL,
      company_id VARCHAR(32),
      user_id VARCHAR(64),
      start_time DATETIME,
      end_time DATETIME,
      event_time DATETIME,
      start_lng DOUBLE,
      start_lat DOUBLE,
      end_lng DOUBLE,
      end_lat DOUBLE,
      ride_duration_sec INT,
      start_grid VARCHAR(32),
      end_grid VARCHAR(32),
      coord_sys VARCHAR(16),
      event_date DATE
    )
    UNIQUE KEY(trip_id)
    DISTRIBUTED BY HASH(trip_id) BUCKETS 1
    PROPERTIES (
      "replication_num" = "1",
      "enable_unique_key_merge_on_write" = "true"
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS bike_rt.ads_bike_trip_cnt_1m (
      window_start DATETIME NOT NULL,
      window_end DATETIME NOT NULL,
      trip_cnt BIGINT,
      uv BIGINT,
      avg_duration_sec DOUBLE
    )
    UNIQUE KEY(window_start, window_end)
    DISTRIBUTED BY HASH(window_start) BUCKETS 1
    PROPERTIES (
      "replication_num" = "1",
      "enable_unique_key_merge_on_write" = "true"
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS bike_rt.ads_bike_start_heat_5m (
      window_start DATETIME NOT NULL,
      window_end DATETIME NOT NULL,
      start_grid VARCHAR(32) NOT NULL,
      center_lng DOUBLE,
      center_lat DOUBLE,
      trip_cnt BIGINT,
      uv BIGINT
    )
    UNIQUE KEY(window_start, window_end, start_grid)
    DISTRIBUTED BY HASH(start_grid) BUCKETS 1
    PROPERTIES (
      "replication_num" = "1",
      "enable_unique_key_merge_on_write" = "true"
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS bike_rt.ads_bike_end_heat_5m (
      window_start DATETIME NOT NULL,
      window_end DATETIME NOT NULL,
      end_grid VARCHAR(32) NOT NULL,
      center_lng DOUBLE,
      center_lat DOUBLE,
      trip_cnt BIGINT,
      uv BIGINT
    )
    UNIQUE KEY(window_start, window_end, end_grid)
    DISTRIBUTED BY HASH(end_grid) BUCKETS 1
    PROPERTIES (
      "replication_num" = "1",
      "enable_unique_key_merge_on_write" = "true"
    )
    """,
]


def wait_for_port(host: str, port: int, timeout_seconds: int = 300) -> None:
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        try:
            with socket.create_connection((host, port), timeout=2):
                return
        except OSError:
            time.sleep(2)
    raise TimeoutError(f"doris fe {host}:{port} not ready within {timeout_seconds}s")


def connect():
    return pymysql.connect(
        host=HOST,
        port=PORT,
        user="root",
        password="",
        charset="utf8mb4",
        autocommit=True,
    )


def ensure_backend(cur) -> None:
    try:
        cur.execute(f'ALTER SYSTEM ADD BACKEND "{HOST}:9050"')
    except Exception as exc:  # noqa: BLE001
        message = str(exc).lower()
        if "already exists" not in message and "same backend exists" not in message:
            raise


def wait_backend_alive(cur, timeout_seconds: int = 300) -> None:
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        cur.execute("SHOW BACKENDS")
        rows = cur.fetchall()
        for row in rows:
            as_text = " ".join(str(item) for item in row)
            if HOST in as_text and "true" in as_text.lower():
                return
        time.sleep(2)
    raise TimeoutError("backend is not alive after registration")


def main() -> None:
    wait_for_port(HOST, PORT)
    conn = connect()
    try:
        with conn.cursor() as cur:
            ensure_backend(cur)
            wait_backend_alive(cur)
            for ddl in DDL_LIST:
                cur.execute(ddl)
            cur.execute("SHOW TABLES FROM bike_rt")
            for row in cur.fetchall():
                print(row[0])
    finally:
        conn.close()


if __name__ == "__main__":
    main()
