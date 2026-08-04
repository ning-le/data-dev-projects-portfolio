-- Export Iceberg ADS tables to MariaDB for Grafana MySQL datasource.

SET spark.sql.catalog.taxi_catalog=org.apache.iceberg.spark.SparkCatalog;
SET spark.sql.catalog.taxi_catalog.type=hadoop;
SET spark.sql.catalog.taxi_catalog.warehouse=hdfs:///warehouse/nyc_taxi_lake;

USE taxi_catalog.taxi_dw;

CREATE OR REPLACE TEMPORARY VIEW mysql_ads_taxi_daily_overview
USING jdbc
OPTIONS (
  url 'jdbc:mysql://localhost:3306/nyc_taxi_ads?useSSL=false&characterEncoding=utf8',
  dbtable 'ads_taxi_daily_overview',
  user 'root',
  password '',
  driver 'com.mysql.cj.jdbc.Driver'
);

CREATE OR REPLACE TEMPORARY VIEW mysql_ads_pickup_zone_top10
USING jdbc
OPTIONS (
  url 'jdbc:mysql://localhost:3306/nyc_taxi_ads?useSSL=false&characterEncoding=utf8',
  dbtable 'ads_pickup_zone_top10',
  user 'root',
  password '',
  driver 'com.mysql.cj.jdbc.Driver'
);

CREATE OR REPLACE TEMPORARY VIEW mysql_ads_pickup_hour_trend
USING jdbc
OPTIONS (
  url 'jdbc:mysql://localhost:3306/nyc_taxi_ads?useSSL=false&characterEncoding=utf8',
  dbtable 'ads_pickup_hour_trend',
  user 'root',
  password '',
  driver 'com.mysql.cj.jdbc.Driver'
);

CREATE OR REPLACE TEMPORARY VIEW mysql_ads_taxi_quality_overview
USING jdbc
OPTIONS (
  url 'jdbc:mysql://localhost:3306/nyc_taxi_ads?useSSL=false&characterEncoding=utf8',
  dbtable 'ads_taxi_quality_overview',
  user 'root',
  password '',
  driver 'com.mysql.cj.jdbc.Driver'
);

CREATE OR REPLACE TEMPORARY VIEW mysql_ads_taxi_quality_rule_result
USING jdbc
OPTIONS (
  url 'jdbc:mysql://localhost:3306/nyc_taxi_ads?useSSL=false&characterEncoding=utf8',
  dbtable 'ads_taxi_quality_rule_result',
  user 'root',
  password '',
  driver 'com.mysql.cj.jdbc.Driver'
);

INSERT INTO mysql_ads_taxi_daily_overview
SELECT * FROM ads_taxi_daily_overview;

INSERT INTO mysql_ads_pickup_zone_top10
SELECT * FROM ads_pickup_zone_top10;

INSERT INTO mysql_ads_pickup_hour_trend
SELECT * FROM ads_pickup_hour_trend;

INSERT INTO mysql_ads_taxi_quality_overview
SELECT * FROM ads_taxi_quality_overview;

INSERT INTO mysql_ads_taxi_quality_rule_result
SELECT * FROM ads_taxi_quality_rule_result;
