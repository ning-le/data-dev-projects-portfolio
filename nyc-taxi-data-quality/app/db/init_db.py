import sqlite3
from pathlib import Path

DB_PATH = Path("db/quality_platform.db")


def init_db():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS task_definitions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_name TEXT UNIQUE NOT NULL,
        source_path TEXT NOT NULL,
        date_column TEXT NOT NULL,
        enabled INTEGER DEFAULT 1,
        created_at TEXT
    )
    """)

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS quality_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_name TEXT NOT NULL,
        rule_type TEXT NOT NULL,
        rule_target TEXT NOT NULL,
        threshold REAL,
        enabled INTEGER DEFAULT 1,
        created_at TEXT
    )
    """)

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS task_runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_name TEXT NOT NULL,
        biz_date TEXT NOT NULL,
        run_type TEXT NOT NULL,
        status TEXT NOT NULL,
        row_count INTEGER DEFAULT 0,
        passed_rules INTEGER DEFAULT 0,
        failed_rules INTEGER DEFAULT 0,
        message TEXT,
        started_at TEXT,
        finished_at TEXT
    )
    """)

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS rule_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        run_id INTEGER NOT NULL,
        rule_type TEXT NOT NULL,
        rule_target TEXT NOT NULL,
        status TEXT NOT NULL,
        actual_value TEXT,
        expected_value TEXT,
        message TEXT
    )
    """)

    conn.commit()
    conn.close()


if __name__ == "__main__":
    init_db()
    print("database initialized")