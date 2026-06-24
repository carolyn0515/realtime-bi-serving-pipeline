SET 'execution.runtime-mode' = 'batch';
SET 'sql-client.execution.result-mode' = 'tableau';

CREATE CATALOG paimon WITH (
    'type' = 'paimon',
    'warehouse' = 'file:/warehouse/paimon'
);

CREATE TEMPORARY TABLE ux_events_raw_bounded (
    event_id STRING,
    session_id STRING,
    user_id STRING,
    order_id STRING,
    order_item_id STRING,
    product_id STRING,
    event_type STRING,
    event_time STRING,
    event_ts AS TO_TIMESTAMP(REPLACE(SUBSTRING(event_time, 1, 19), 'T', ' ')),
    category_code STRING,
    price DOUBLE,
    payment_type STRING,
    shipping_fee DOUBLE,
    customer_state STRING,
    seller_state STRING,
    emitted_at STRING,
    kafka_partition INT METADATA FROM 'partition' VIRTUAL,
    kafka_offset BIGINT METADATA FROM 'offset' VIRTUAL,
    kafka_timestamp TIMESTAMP_LTZ(3) METADATA FROM 'timestamp' VIRTUAL,
    WATERMARK FOR event_ts AS event_ts - INTERVAL '30' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'ux-events',
    'properties.bootstrap.servers' = 'kafka:29092',
    'properties.group.id' = 'flink-ux-events-bronze-bootstrap',
    'scan.startup.mode' = 'earliest-offset',
    'scan.bounded.mode' = 'latest-offset',
    'format' = 'json',
    'json.ignore-parse-errors' = 'false',
    'json.fail-on-missing-field' = 'false'
);

USE CATALOG paimon;

CREATE DATABASE IF NOT EXISTS lakehouse;

USE lakehouse;

DROP TABLE IF EXISTS ux_events_bronze;

CREATE TABLE IF NOT EXISTS ux_events_bronze (
    event_id STRING,
    session_id STRING,
    user_id STRING,
    order_id STRING,
    order_item_id STRING,
    product_id STRING,
    event_type STRING,
    event_time STRING,
    event_ts TIMESTAMP(3),
    category_code STRING,
    price DOUBLE,
    payment_type STRING,
    shipping_fee DOUBLE,
    customer_state STRING,
    seller_state STRING,
    emitted_at STRING,
    kafka_partition INT,
    kafka_offset BIGINT,
    kafka_timestamp TIMESTAMP_LTZ(3),
    dt STRING
) PARTITIONED BY (dt)
WITH (
    'bucket' = '-1',
    'file.format' = 'parquet',
    'snapshot.num-retained.min' = '10',
    'snapshot.num-retained.max' = '30'
);

INSERT INTO ux_events_bronze
SELECT
    event_id,
    session_id,
    user_id,
    order_id,
    order_item_id,
    product_id,
    event_type,
    event_time,
    event_ts,
    category_code,
    price,
    payment_type,
    shipping_fee,
    customer_state,
    seller_state,
    emitted_at,
    kafka_partition,
    kafka_offset,
    kafka_timestamp,
    DATE_FORMAT(event_ts, 'yyyy-MM-dd') AS dt
FROM default_catalog.default_database.ux_events_raw_bounded;
