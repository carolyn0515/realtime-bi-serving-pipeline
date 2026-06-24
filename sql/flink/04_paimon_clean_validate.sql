SET 'execution.runtime-mode' = 'batch';
SET 'sql-client.execution.result-mode' = 'tableau';
SET 'table.dml-sync' = 'true';

CREATE CATALOG paimon WITH (
    'type' = 'paimon',
    'warehouse' = 'file:/warehouse/paimon'
);

USE CATALOG paimon;

CREATE DATABASE IF NOT EXISTS lakehouse;

USE lakehouse;

DROP TABLE IF EXISTS ux_events_clean;
DROP TABLE IF EXISTS ux_events_invalid;

CREATE TABLE IF NOT EXISTS ux_events_clean (
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

CREATE TABLE IF NOT EXISTS ux_events_invalid (
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
    validation_error STRING,
    rejected_at TIMESTAMP(3),
    dt STRING
) PARTITIONED BY (dt)
WITH (
    'bucket' = '-1',
    'file.format' = 'parquet',
    'snapshot.num-retained.min' = '10',
    'snapshot.num-retained.max' = '30'
);

CREATE TEMPORARY VIEW ux_events_validated AS
SELECT
    *,
    CASE
        WHEN event_id IS NULL OR TRIM(event_id) = '' THEN 'missing_event_id'
        WHEN session_id IS NULL OR TRIM(session_id) = '' THEN 'missing_session_id'
        WHEN user_id IS NULL OR TRIM(user_id) = '' THEN 'missing_user_id'
        WHEN product_id IS NULL OR TRIM(product_id) = '' THEN 'missing_product_id'
        WHEN event_type IS NULL OR event_type NOT IN ('view', 'cart', 'purchase') THEN 'invalid_event_type'
        WHEN event_time IS NULL OR TRIM(event_time) = '' OR event_ts IS NULL THEN 'invalid_event_time'
        WHEN price IS NULL OR price < 0 THEN 'invalid_price'
        WHEN category_code IS NULL OR TRIM(category_code) = '' THEN 'missing_category_code'
        WHEN customer_state IS NULL OR TRIM(customer_state) = '' THEN 'missing_customer_state'
        WHEN seller_state IS NULL OR TRIM(seller_state) = '' THEN 'missing_seller_state'
        WHEN event_type = 'purchase' AND (order_id IS NULL OR TRIM(order_id) = '') THEN 'missing_purchase_order_id'
        WHEN event_type = 'purchase' AND (order_item_id IS NULL OR TRIM(order_item_id) = '') THEN 'missing_purchase_order_item_id'
        WHEN event_type = 'purchase' AND (payment_type IS NULL OR TRIM(payment_type) = '') THEN 'missing_purchase_payment_type'
        WHEN event_type = 'purchase' AND (shipping_fee IS NULL OR shipping_fee < 0) THEN 'invalid_purchase_shipping_fee'
        WHEN event_type IN ('view', 'cart') AND (
            order_id IS NOT NULL
            OR order_item_id IS NOT NULL
            OR payment_type IS NOT NULL
            OR shipping_fee IS NOT NULL
        ) THEN 'non_purchase_has_purchase_fields'
        WHEN kafka_partition IS NULL OR kafka_offset IS NULL THEN 'missing_kafka_metadata'
        ELSE NULL
    END AS validation_error
FROM ux_events_bronze;

INSERT INTO ux_events_clean
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
    dt
FROM ux_events_validated
WHERE validation_error IS NULL;

INSERT INTO ux_events_invalid
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
    validation_error,
    CURRENT_TIMESTAMP,
    COALESCE(dt, 'unknown')
FROM ux_events_validated
WHERE validation_error IS NOT NULL;
