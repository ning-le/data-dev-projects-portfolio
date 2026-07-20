from datetime import datetime
from pathlib import Path
import sqlite3
from datetime import datetime, timedelta
import pandas as pd

from app.config.loader import load_yaml

from app.db.db_utils import get_connection
from app.core.checks import (
    check_fk_exists,
    check_non_negative,
    check_not_null,
    check_row_count_fluctuation,
)

BASE_DIR = Path(__file__).resolve().parent.parent.parent
TASKS_PATH = BASE_DIR / "configs" / "tasks.yaml"
RULES_PATH = BASE_DIR / "configs" / "rules.yaml"
ZONE_PATH = BASE_DIR / "data" / "sample" / "taxi_zone_lookup.csv"


def run_task(task_name: str, biz_date: str, run_type: str = "run"):
    tasks_config = load_yaml(str(TASKS_PATH))
    rules_config = load_yaml(str(RULES_PATH))

    tasks = tasks_config["tasks"]
    rules = rules_config["rules"]

    task = next(
        (t for t in tasks if t["task_name"] == task_name and t["enabled"]),
        None
    )

    if task is None:
        raise ValueError(f"task not found or disabled: {task_name}")

    task_rules = [r for r in rules if r["task_name"] == task_name]

    source_path = BASE_DIR / task["source_path"]
    df = pd.read_parquet(source_path)
    df = df[df[task["date_column"]] == biz_date].copy()

    zone_df = pd.read_csv(ZONE_PATH)

    conn = get_connection()
    cursor = conn.cursor()

    started_at = datetime.now().isoformat()

    cursor.execute(
        """
        INSERT INTO task_runs (
            task_name, biz_date, run_type, status, row_count,
            passed_rules, failed_rules, message, started_at, finished_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (

            task_name,
            biz_date,
            run_type,
            "running",
            len(df),
            0,
            0,
            "",
            started_at,
            None,

        ),
    )
    conn.commit()
    run_id = cursor.lastrowid

    passed = 0
    failed = 0

    for rule in task_rules:
        rule_type = rule["rule_type"]
        rule_target = rule["rule_target"]

        if rule_type == "not_null":
            result = check_not_null(df, rule_target)
        elif rule_type == "non_negative":
            result = check_non_negative(df, rule_target)
        elif rule_type == "fk_exists":
            result = check_fk_exists(df, rule_target, zone_df)
        elif rule_type == "row_count_fluctuation":
            previous_count = get_previous_day_row_count(task_name, biz_date)
            threshold = rule.get("threshold", 0.3)
            result = check_row_count_fluctuation(len(df), previous_count, threshold)
        else:
            continue

        if result["status"] == "passed":
            passed += 1
        else:
            failed += 1

        cursor.execute(
            """
            INSERT INTO rule_results (
                run_id, rule_type, rule_target, status,
                actual_value, expected_value, message
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                run_id,
                rule_type,
                rule_target,
                result["status"],
                result["actual_value"],
                result["expected_value"],
                result["message"],
            ),
        )

    finished_at = datetime.now().isoformat()
    final_status = "success" if failed == 0 else "failed"
    final_message = f"run completed: passed={passed}, failed={failed}"

    cursor.execute(
        """
        UPDATE task_runs
        SET status = ?, passed_rules = ?, failed_rules = ?, message = ?, finished_at = ?
        WHERE id = ?
        """,
        (
            final_status,
            passed,
            failed,
            final_message,
            finished_at,
            run_id,
        ),
    )

    conn.commit()
    conn.close()

    return {
        "run_id": run_id,
        "task_name": task_name,
        "biz_date": biz_date,
        "row_count": len(df),
        "passed_rules": passed,
        "failed_rules": failed,
        "status": final_status,
    }


def list_runs(limit: int = 10):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        """
        SELECT id, task_name, biz_date, run_type, status, row_count,
               passed_rules, failed_rules, message, started_at, finished_at
        FROM task_runs
        ORDER BY id DESC
        LIMIT ?
        """,
        (limit,),
    )

    rows = cursor.fetchall()
    conn.close()
    return rows


def rerun_task(run_id: int):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        """
        SELECT task_name, biz_date
        FROM task_runs
        WHERE id = ?
        """,
        (run_id,),
    )

    row = cursor.fetchone()
    conn.close()

    if row is None:
        raise ValueError(f"run_id not found: {run_id}")

    task_name, biz_date = row
    return run_task(task_name, biz_date, run_type="rerun")


def backfill_task(task_name: str, start_date: str, end_date: str):
    start = datetime.strptime(start_date, "%Y-%m-%d").date()
    end = datetime.strptime(end_date, "%Y-%m-%d").date()

    if start > end:
        raise ValueError("start_date cannot be greater than end_date")

    results = []
    current = start

    while current <= end:
        biz_date = current.isoformat()
        result = run_task(task_name, biz_date, run_type="backfill")
        results.append(result)
        current += timedelta(days=1)

    return results


def get_previous_day_row_count(task_name: str, biz_date: str):
    current_date = datetime.strptime(biz_date, "%Y-%m-%d").date()
    previous_date = (current_date - timedelta(days=1)).isoformat()

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        """
        SELECT row_count
        FROM task_runs
        WHERE task_name = ? AND biz_date = ? AND status IN ('success', 'failed')
        ORDER BY id DESC
        LIMIT 1
        """,
        (task_name, previous_date),
    )

    row = cursor.fetchone()
    conn.close()

    if row is None:
        return 0
    return row[0]