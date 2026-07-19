import argparse
import json
import sqlite3
from datetime import date, timedelta
from pathlib import Path
from typing import Any, Optional

import pandas as pd
import yaml


BASE_DIR = Path(__file__).resolve().parents[1]
DEFAULT_CONFIG = BASE_DIR / "config" / "rules.yaml"
DEFAULT_DB = BASE_DIR / "quality_runs.db"


def connect(db_path: Path = DEFAULT_DB) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS task_run (
            run_id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_name TEXT NOT NULL,
            biz_date TEXT NOT NULL,
            run_type TEXT NOT NULL,
            status TEXT NOT NULL,
            row_count INTEGER NOT NULL,
            failed_rule_count INTEGER NOT NULL,
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS rule_result (
            result_id INTEGER PRIMARY KEY AUTOINCREMENT,
            run_id INTEGER NOT NULL,
            rule_name TEXT NOT NULL,
            rule_type TEXT NOT NULL,
            status TEXT NOT NULL,
            failed_count INTEGER NOT NULL,
            message TEXT,
            detail_json TEXT,
            FOREIGN KEY(run_id) REFERENCES task_run(run_id)
        )
        """
    )
    return conn


def load_config(path: Path = DEFAULT_CONFIG) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_task_frame(task: dict[str, Any], biz_date: str) -> pd.DataFrame:
    df = pd.read_csv(BASE_DIR / task["input"])
    date_column = task.get("date_column")
    if date_column and date_column in df.columns:
        df = df[df[date_column].astype(str) == biz_date].copy()
    return df


def check_not_null(df: pd.DataFrame, rule: dict[str, Any]) -> tuple[int, str, dict[str, Any]]:
    column = rule["column"]
    failed = int(df[column].isna().sum() + (df[column].astype(str).str.strip() == "").sum())
    return failed, f"{column} null or blank rows: {failed}", {"column": column}


def check_non_negative(df: pd.DataFrame, rule: dict[str, Any]) -> tuple[int, str, dict[str, Any]]:
    column = rule["column"]
    values = pd.to_numeric(df[column], errors="coerce")
    failed = int((values < 0).sum())
    return failed, f"{column} negative rows: {failed}", {"column": column}


def check_fk_exists(df: pd.DataFrame, rule: dict[str, Any]) -> tuple[int, str, dict[str, Any]]:
    column = rule["column"]
    ref_df = pd.read_csv(BASE_DIR / rule["ref_input"])
    ref_values = set(ref_df[rule["ref_column"]].dropna().astype(str))
    missing_mask = ~df[column].dropna().astype(str).isin(ref_values)
    failed = int(missing_mask.sum())
    return failed, f"{column} missing in reference table: {failed}", {"column": column}


def previous_success_row_count(conn: sqlite3.Connection, task_name: str, biz_date: str) -> Optional[int]:
    row = conn.execute(
        """
        SELECT row_count
        FROM task_run
        WHERE task_name = ?
          AND biz_date < ?
          AND status = 'success'
        ORDER BY biz_date DESC, run_id DESC
        LIMIT 1
        """,
        (task_name, biz_date),
    ).fetchone()
    return None if row is None else int(row[0])


def check_row_count_fluctuation(
    conn: sqlite3.Connection,
    df: pd.DataFrame,
    task_name: str,
    biz_date: str,
    rule: dict[str, Any],
) -> tuple[int, str, dict[str, Any]]:
    current = len(df)
    previous = previous_success_row_count(conn, task_name, biz_date)
    if previous is None or previous == 0:
        return 0, "no previous success row count, skipped", {"current": current, "previous": previous}
    change_rate = abs(current - previous) / previous
    max_change_rate = float(rule.get("max_change_rate", 0.5))
    failed = 1 if change_rate > max_change_rate else 0
    message = f"row count change rate: {change_rate:.2%}, threshold: {max_change_rate:.2%}"
    return failed, message, {"current": current, "previous": previous, "change_rate": change_rate}


def execute_rule(
    conn: sqlite3.Connection,
    df: pd.DataFrame,
    task_name: str,
    biz_date: str,
    rule: dict[str, Any],
) -> tuple[str, int, str, dict[str, Any]]:
    rule_type = rule["type"]
    if rule_type == "not_null":
        failed_count, message, detail = check_not_null(df, rule)
    elif rule_type == "non_negative":
        failed_count, message, detail = check_non_negative(df, rule)
    elif rule_type == "fk_exists":
        failed_count, message, detail = check_fk_exists(df, rule)
    elif rule_type == "row_count_fluctuation":
        failed_count, message, detail = check_row_count_fluctuation(conn, df, task_name, biz_date, rule)
    else:
        raise ValueError(f"unsupported rule type: {rule_type}")
    status = "success" if failed_count == 0 else "failed"
    return status, failed_count, message, detail


def run_task(task_name: str, biz_date: str, run_type: str, config_path: Path = DEFAULT_CONFIG) -> int:
    config = load_config(config_path)
    task = config["tasks"][task_name]
    df = load_task_frame(task, biz_date)
    conn = connect()
    results = []
    try:
        for rule in task["rules"]:
            status, failed_count, message, detail = execute_rule(conn, df, task_name, biz_date, rule)
            results.append((rule, status, failed_count, message, detail))
        failed_rule_count = sum(1 for _, status, _, _, _ in results if status == "failed")
        overall_status = "success" if failed_rule_count == 0 else "failed"
        cur = conn.execute(
            """
            INSERT INTO task_run(task_name, biz_date, run_type, status, row_count, failed_rule_count)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (task_name, biz_date, run_type, overall_status, len(df), failed_rule_count),
        )
        run_id = int(cur.lastrowid)
        for rule, status, failed_count, message, detail in results:
            conn.execute(
                """
                INSERT INTO rule_result(run_id, rule_name, rule_type, status, failed_count, message, detail_json)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    run_id,
                    rule["name"],
                    rule["type"],
                    status,
                    failed_count,
                    message,
                    json.dumps(detail, ensure_ascii=False),
                ),
            )
        conn.commit()
        print(f"run_id={run_id} task={task_name} biz_date={biz_date} status={overall_status}")
        return run_id
    finally:
        conn.close()


def date_range(start_date: str, end_date: str) -> list[str]:
    start = date.fromisoformat(start_date)
    end = date.fromisoformat(end_date)
    days = []
    current = start
    while current <= end:
        days.append(current.isoformat())
        current += timedelta(days=1)
    return days


def main() -> None:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    for command in ["run", "rerun"]:
        sub = subparsers.add_parser(command)
        sub.add_argument("--task", required=True)
        sub.add_argument("--biz-date", required=True)

    backfill = subparsers.add_parser("backfill")
    backfill.add_argument("--task", required=True)
    backfill.add_argument("--start-date", required=True)
    backfill.add_argument("--end-date", required=True)

    args = parser.parse_args()
    if args.command in {"run", "rerun"}:
        run_task(args.task, args.biz_date, args.command)
    elif args.command == "backfill":
        for biz_date in date_range(args.start_date, args.end_date):
            run_task(args.task, biz_date, "backfill")


if __name__ == "__main__":
    main()
