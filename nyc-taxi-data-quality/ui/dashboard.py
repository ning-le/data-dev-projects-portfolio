import sqlite3
import pandas as pd
import streamlit as st

DB_PATH = "db/quality_platform.db"

st.set_page_config(page_title="NYC Taxi Quality Platform", layout="wide")
st.title("NYC Taxi Quality Platform")

conn = sqlite3.connect(DB_PATH)

task_runs = pd.read_sql_query(
    """
    SELECT id, task_name, biz_date, run_type, status, row_count,
           passed_rules, failed_rules, message, started_at, finished_at
    FROM task_runs
    ORDER BY id DESC
    """,
    conn,
)

rule_results = pd.read_sql_query(
    """
    SELECT id, run_id, rule_type, rule_target, status,
           actual_value, expected_value, message
    FROM rule_results
    ORDER BY id DESC
    """,
    conn,
)

conn.close()

col1, col2, col3, col4 = st.columns(4)
col1.metric("Total Runs", len(task_runs))
col2.metric("Success Runs", int((task_runs["status"] == "success").sum()) if not task_runs.empty else 0)
col3.metric("Failed Runs", int((task_runs["status"] == "failed").sum()) if not task_runs.empty else 0)
col4.metric("Total Rule Results", len(rule_results))

st.subheader("Recent Task Runs")
st.dataframe(task_runs)

st.subheader("Failed Runs")
failed_runs = task_runs[task_runs["status"] == "failed"]
st.dataframe(failed_runs)

st.subheader("Recent Rule Results")
st.dataframe(rule_results)

st.subheader("Failed Rule Results")
failed_rules = rule_results[rule_results["status"] == "failed"]
st.dataframe(failed_rules)

st.subheader("Latest Task Results")
try:
    conn = sqlite3.connect(DB_PATH)
    latest_runs = pd.read_sql_query(
        """
        SELECT task_name, biz_date, latest_run_id, run_type, status, row_count,
               passed_rules, failed_rules, message, updated_at
        FROM task_run_latest
        ORDER BY biz_date DESC, task_name
        """,
        conn,
    )
    conn.close()
    st.dataframe(latest_runs)
except Exception as exc:  # noqa: BLE001
    st.info(f"Latest tables are not initialized yet: {exc}")

st.subheader("Latest Failed Rules")
try:
    conn = sqlite3.connect(DB_PATH)
    latest_failed_rules = pd.read_sql_query(
        """
        SELECT task_name, biz_date, rule_type, rule_target, latest_run_id,
               actual_value, expected_value, message, updated_at
        FROM rule_result_latest
        WHERE status = 'failed'
        ORDER BY biz_date DESC, rule_type, rule_target
        """,
        conn,
    )
    conn.close()
    st.dataframe(latest_failed_rules)
except Exception as exc:  # noqa: BLE001
    st.info(f"Latest rule tables are not initialized yet: {exc}")
