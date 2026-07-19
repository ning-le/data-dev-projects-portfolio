from pathlib import Path

import pandas as pd
import sqlite3
import streamlit as st


BASE_DIR = Path(__file__).resolve().parent
DB_PATH = BASE_DIR / "quality_runs.db"


def read_sql(query: str) -> pd.DataFrame:
    if not DB_PATH.exists():
        return pd.DataFrame()
    with sqlite3.connect(DB_PATH) as conn:
        return pd.read_sql_query(query, conn)


st.set_page_config(page_title="NYC Taxi Data Quality", layout="wide")
st.title("NYC Taxi Data Quality")

runs = read_sql(
    """
    SELECT run_id, task_name, biz_date, run_type, status, row_count, failed_rule_count, created_at
    FROM task_run
    ORDER BY run_id DESC
    """
)

if runs.empty:
    st.info("No task run records. Run quality_engine.py first.")
    st.stop()

left, right = st.columns([2, 3])

with left:
    st.subheader("Task Runs")
    st.dataframe(runs, use_container_width=True, hide_index=True)
    selected_run_id = st.selectbox("Run ID", runs["run_id"].tolist())

with right:
    st.subheader("Rule Results")
    results = read_sql(
        f"""
        SELECT rule_name, rule_type, status, failed_count, message, detail_json
        FROM rule_result
        WHERE run_id = {int(selected_run_id)}
        ORDER BY result_id
        """
    )
    st.dataframe(results, use_container_width=True, hide_index=True)

st.subheader("Failure Summary")
failures = read_sql(
    """
    SELECT tr.task_name, tr.biz_date, rr.rule_name, rr.rule_type, rr.failed_count, rr.message
    FROM rule_result rr
    JOIN task_run tr ON rr.run_id = tr.run_id
    WHERE rr.status = 'failed'
    ORDER BY tr.biz_date DESC, rr.result_id DESC
    """
)
st.dataframe(failures, use_container_width=True, hide_index=True)
