CREATE DATABASE IF NOT EXISTS flight_ads DEFAULT CHARACTER SET utf8;
USE flight_ads;

DROP TABLE IF EXISTS ads_airline_delay_rank;
CREATE TABLE ads_airline_delay_rank (
    airline_code VARCHAR(20),
    airline_name VARCHAR(100),
    flight_cnt BIGINT,
    valid_flight_cnt BIGINT,
    arrival_delay_cnt BIGINT,
    avg_arrival_delay_min DECIMAL(16,2),
    arrival_delay_rate DECIMAL(16,4),
    rank_no INT,
    flight_date DATE,
    KEY idx_date_rank (flight_date, rank_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS ads_route_delay_topn;
CREATE TABLE ads_route_delay_topn (
    route_code VARCHAR(50),
    origin_airport VARCHAR(20),
    destination_airport VARCHAR(20),
    flight_cnt BIGINT,
    valid_flight_cnt BIGINT,
    arrival_delay_cnt BIGINT,
    avg_arrival_delay_min DECIMAL(16,2),
    arrival_delay_rate DECIMAL(16,4),
    rank_no INT,
    flight_date DATE,
    KEY idx_date_rank (flight_date, rank_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS ads_airport_delay_topn;
CREATE TABLE ads_airport_delay_topn (
    airport_code VARCHAR(20),
    airport_name VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(20),
    flight_cnt BIGINT,
    valid_flight_cnt BIGINT,
    departure_delay_cnt BIGINT,
    avg_departure_delay_min DECIMAL(16,2),
    departure_delay_rate DECIMAL(16,4),
    rank_no INT,
    flight_date DATE,
    KEY idx_date_rank (flight_date, rank_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS ads_hour_delay_trend;
CREATE TABLE ads_hour_delay_trend (
    scheduled_departure_hour INT,
    flight_cnt BIGINT,
    valid_flight_cnt BIGINT,
    departure_delay_cnt BIGINT,
    arrival_delay_cnt BIGINT,
    avg_departure_delay_min DECIMAL(16,2),
    avg_arrival_delay_min DECIMAL(16,2),
    departure_delay_rate DECIMAL(16,4),
    arrival_delay_rate DECIMAL(16,4),
    flight_date DATE,
    KEY idx_date_hour (flight_date, scheduled_departure_hour)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
