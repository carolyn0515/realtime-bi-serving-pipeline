SET 'execution.runtime-mode' = 'streaming';
SET 'sql-client.execution.result-mode' = 'tableau';

CREATE TABLE ux_events_raw (
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
    'properties.group.id' = 'flink-ux-events-smoke',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json',
    'json.ignore-parse-errors' = 'false',
    'json.fail-on-missing-field' = 'false'
);

SELECT
    kafka_partition,
    kafka_offset,
    session_id,
    event_type,
    event_ts,
    order_id,
    payment_type,
    shipping_fee,
    category_code,
    price
FROM ux_events_raw
LIMIT 20;
