from pathlib import Path

import pandas as pd

BASE_DIR = Path(__file__).resolve().parent.parent

RAW_TRIP_PATH = BASE_DIR / "data" / "raw" / "yellow_tripdata_2025-01.parquet"
RAW_ZONE_PATH = BASE_DIR / "data" / "raw" / "taxi_zone_lookup.csv"
SAMPLE_TRIP_PATH = BASE_DIR / "data" / "sample" / "yellow_tripdata_sample.parquet"
SAMPLE_ZONE_PATH = BASE_DIR / "data" / "sample" / "taxi_zone_lookup.csv"


def make_trip_sample():
    df = pd.read_parquet(RAW_TRIP_PATH)

    selected_columns = [
        "VendorID",
        "tpep_pickup_datetime",
        "tpep_dropoff_datetime",
        "passenger_count",
        "trip_distance",
        "PULocationID",
        "DOLocationID",
        "fare_amount",
        "total_amount",
        "payment_type",
    ]

    df = df[selected_columns].copy()
    df["biz_date"] = pd.to_datetime(df["tpep_pickup_datetime"]).dt.date.astype(str)

    filtered = df[df["biz_date"].between("2025-01-10", "2025-01-20")].copy()

    sample = (
        filtered.groupby("biz_date", group_keys=False)
        .head(3000)
        .copy()
    )

    if len(sample) >= 6:
        sample.loc[sample.index[0], "fare_amount"] = -10
        sample.loc[sample.index[1], "PULocationID"] = None
        sample.loc[sample.index[2], "DOLocationID"] = 999999
        sample.loc[sample.index[3], "total_amount"] = None
        sample.loc[sample.index[4], "trip_distance"] = -5
        sample = pd.concat([sample, sample.iloc[[5]]], ignore_index=True)

    SAMPLE_TRIP_PATH.parent.mkdir(parents=True, exist_ok=True)
    sample.to_parquet(SAMPLE_TRIP_PATH, index=False)

    print(f"trip sample rows: {len(sample)}")
    print(f"trip sample saved to: {SAMPLE_TRIP_PATH}")
    print(sample["biz_date"].value_counts().sort_index())


def make_zone_sample():
    df = pd.read_csv(RAW_ZONE_PATH)
    SAMPLE_ZONE_PATH.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(SAMPLE_ZONE_PATH, index=False)
    print(f"zone sample rows: {len(df)}")
    print(f"zone sample saved to: {SAMPLE_ZONE_PATH}")


if __name__ == "__main__":
    make_trip_sample()
    make_zone_sample()