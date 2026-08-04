CREATE DATABASE IF NOT EXISTS nyc_taxi_ads DEFAULT CHARACTER SET utf8;
USE nyc_taxi_ads;

DROP TABLE IF EXISTS ads_taxi_daily_overview;
CREATE TABLE ads_taxi_daily_overview (
    biz_date DATE PRIMARY KEY,
    trip_cnt BIGINT,
    valid_trip_cnt BIGINT,
    total_amount DECIMAL(18,2),
    avg_amount DECIMAL(18,2),
    avg_distance DECIMAL(18,2),
    avg_duration_sec DECIMAL(18,2),
    abnormal_trip_cnt BIGINT,
    abnormal_rate DECIMAL(18,4),
    KEY idx_trip_cnt (trip_cnt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS ads_pickup_zone_top10;
CREATE TABLE ads_pickup_zone_top10 (
    biz_date DATE,
    pickup_location_id BIGINT,
    pickup_borough VARCHAR(100),
    pickup_zone VARCHAR(200),
    trip_cnt BIGINT,
    total_amount DECIMAL(18,2),
    avg_amount DECIMAL(18,2),
    rank_no INT,
    PRIMARY KEY (biz_date, rank_no),
    KEY idx_date_trip (biz_date, trip_cnt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS ads_pickup_hour_trend;
CREATE TABLE ads_pickup_hour_trend (
    biz_date DATE,
    pickup_hour INT,
    trip_cnt BIGINT,
    valid_trip_cnt BIGINT,
    total_amount DECIMAL(18,2),
    avg_amount DECIMAL(18,2),
    avg_distance DECIMAL(18,2),
    abnormal_trip_cnt BIGINT,
    abnormal_rate DECIMAL(18,4),
    PRIMARY KEY (biz_date, pickup_hour)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS ads_taxi_quality_overview;
CREATE TABLE ads_taxi_quality_overview (
    biz_date DATE PRIMARY KEY,
    total_trip_cnt BIGINT,
    valid_trip_cnt BIGINT,
    invalid_trip_cnt BIGINT,
    invalid_amount_cnt BIGINT,
    invalid_distance_cnt BIGINT,
    invalid_location_cnt BIGINT,
    invalid_amount_rate DECIMAL(18,4),
    invalid_distance_rate DECIMAL(18,4),
    invalid_location_rate DECIMAL(18,4),
    overall_invalid_rate DECIMAL(18,4)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS ads_taxi_quality_rule_result;
CREATE TABLE ads_taxi_quality_rule_result (
    biz_date DATE,
    rule_name VARCHAR(100),
    rule_target VARCHAR(200),
    check_status VARCHAR(20),
    failed_count BIGINT,
    total_count BIGINT,
    failed_rate DECIMAL(18,4),
    expected_value VARCHAR(300),
    PRIMARY KEY (biz_date, rule_name, rule_target)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
