import pandas as pd


def check_not_null(df: pd.DataFrame, column: str):
    null_count = int(df[column].isna().sum())
    ok = null_count == 0
    return {
        "status": "passed" if ok else "failed",
        "actual_value": str(null_count),
        "expected_value": "0",
        "message": f"{column} null_count={null_count}",
    }


def check_non_negative(df: pd.DataFrame, column: str):
    bad_count = int((df[column] < 0).fillna(False).sum())
    ok = bad_count == 0
    return {
        "status": "passed" if ok else "failed",
        "actual_value": str(bad_count),
        "expected_value": "0",
        "message": f"{column} negative_count={bad_count}",
    }


def check_fk_exists(df: pd.DataFrame, column: str, zone_df: pd.DataFrame):
    valid_ids = set(zone_df["LocationID"].dropna().astype(int).tolist())
    actual_ids = df[column].dropna().astype(int)
    bad_count = int((~actual_ids.isin(valid_ids)).sum())
    ok = bad_count == 0
    return {
        "status": "passed" if ok else "failed",
        "actual_value": str(bad_count),
        "expected_value": "0",
        "message": f"{column} invalid_fk_count={bad_count}",
    }


def check_row_count_fluctuation(current_count: int, previous_count: int, threshold: float):
    if previous_count == 0:
        return {
            "status": "passed",
            "actual_value": str(current_count),
            "expected_value": f"previous_count={previous_count}",
            "message": "previous day row count is 0, fluctuation check skipped",
        }

    ratio = abs(current_count - previous_count) / previous_count
    ok = ratio <= threshold

    return {
        "status": "passed" if ok else "failed",
        "actual_value": f"{ratio:.4f}",
        "expected_value": f"<={threshold}",
        "message": f"row_count fluctuation ratio={ratio:.4f}, current={current_count}, previous={previous_count}",
    }