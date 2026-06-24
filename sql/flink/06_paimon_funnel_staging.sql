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

DROP TABLE IF EXISTS session_funnel_staging;
DROP TABLE IF EXISTS mart_funnel_1h_staging;

CREATE TABLE IF NOT EXISTS session_funnel_staging (
    session_id STRING,
    user_id STRING,
    product_id STRING,
    category_code STRING,
    price DOUBLE,
    price_tier STRING,
    customer_state STRING,
    seller_state STRING,
    first_event_ts TIMESTAMP(3),
    view_ts TIMESTAMP(3),
    cart_ts TIMESTAMP(3),
    purchase_ts TIMESTAMP(3),
    has_view BOOLEAN,
    has_cart BOOLEAN,
    has_purchase BOOLEAN,
    order_id STRING,
    order_item_id STRING,
    payment_type STRING,
    shipping_fee DOUBLE,
    source_event_count BIGINT,
    duplicate_event_count BIGINT,
    first_kafka_partition INT,
    first_kafka_offset BIGINT,
    built_at TIMESTAMP(3),
    dt STRING
) PARTITIONED BY (dt)
WITH (
    'bucket' = '-1',
    'file.format' = 'parquet',
    'snapshot.num-retained.min' = '10',
    'snapshot.num-retained.max' = '30'
);

CREATE TABLE IF NOT EXISTS mart_funnel_1h_staging (
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    category_code STRING,
    price_tier STRING,
    customer_state STRING,
    seller_state STRING,
    view_count BIGINT,
    cart_count BIGINT,
    purchase_count BIGINT,
    view_session_count BIGINT,
    cart_session_count BIGINT,
    purchase_session_count BIGINT,
    view_to_cart_rate DOUBLE,
    cart_to_purchase_rate DOUBLE,
    view_to_purchase_rate DOUBLE,
    late_event_count BIGINT,
    duplicate_event_count BIGINT,
    malformed_event_count BIGINT,
    source_event_count BIGINT,
    built_at TIMESTAMP(3),
    dt STRING
) PARTITIONED BY (dt)
WITH (
    'bucket' = '-1',
    'file.format' = 'parquet',
    'snapshot.num-retained.min' = '10',
    'snapshot.num-retained.max' = '30'
);

CREATE TEMPORARY VIEW clean_enriched AS
SELECT
    *,
    CASE
        WHEN price < 50 THEN 'low'
        WHEN price < 150 THEN 'mid'
        ELSE 'high'
    END AS price_tier,
    TO_TIMESTAMP(DATE_FORMAT(event_ts, 'yyyy-MM-dd HH:00:00')) AS window_start,
    TO_TIMESTAMP(DATE_FORMAT(event_ts + INTERVAL '1' HOUR, 'yyyy-MM-dd HH:00:00')) AS window_end
FROM ux_events_clean;

INSERT INTO session_funnel_staging
SELECT
    session_id,
    MAX(user_id) AS user_id,
    product_id,
    MAX(category_code) AS category_code,
    MAX(price) AS price,
    MAX(price_tier) AS price_tier,
    MAX(customer_state) AS customer_state,
    MAX(seller_state) AS seller_state,
    MIN(event_ts) AS first_event_ts,
    MIN(CASE WHEN event_type = 'view' THEN event_ts END) AS view_ts,
    MIN(CASE WHEN event_type = 'cart' THEN event_ts END) AS cart_ts,
    MIN(CASE WHEN event_type = 'purchase' THEN event_ts END) AS purchase_ts,
    COUNT(CASE WHEN event_type = 'view' THEN 1 END) > 0 AS has_view,
    COUNT(CASE WHEN event_type = 'cart' THEN 1 END) > 0 AS has_cart,
    COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) > 0 AS has_purchase,
    MAX(order_id) AS order_id,
    MAX(order_item_id) AS order_item_id,
    MAX(payment_type) AS payment_type,
    MAX(shipping_fee) AS shipping_fee,
    COUNT(*) AS source_event_count,
    COUNT(*) - COUNT(DISTINCT event_id) AS duplicate_event_count,
    MIN(kafka_partition) AS first_kafka_partition,
    MIN(kafka_offset) AS first_kafka_offset,
    CURRENT_TIMESTAMP AS built_at,
    DATE_FORMAT(MIN(event_ts), 'yyyy-MM-dd') AS dt
FROM clean_enriched
GROUP BY
    session_id,
    product_id;

CREATE TEMPORARY VIEW session_funnel_enriched AS
SELECT
    *,
    TO_TIMESTAMP(DATE_FORMAT(view_ts, 'yyyy-MM-dd HH:00:00')) AS window_start,
    TO_TIMESTAMP(DATE_FORMAT(view_ts + INTERVAL '1' HOUR, 'yyyy-MM-dd HH:00:00')) AS window_end
FROM session_funnel_staging
WHERE has_view = TRUE
  AND view_ts IS NOT NULL;

CREATE TEMPORARY VIEW hourly_funnel_counts AS
SELECT
    window_start,
    window_end,
    category_code,
    price_tier,
    customer_state,
    seller_state,
    COUNT(CASE WHEN has_view THEN 1 END) AS view_count,
    COUNT(CASE WHEN has_cart THEN 1 END) AS cart_count,
    COUNT(CASE WHEN has_purchase THEN 1 END) AS purchase_count,
    COUNT(CASE WHEN has_view THEN 1 END) AS view_session_count,
    COUNT(CASE WHEN has_cart THEN 1 END) AS cart_session_count,
    COUNT(CASE WHEN has_purchase THEN 1 END) AS purchase_session_count,
    CAST(0 AS BIGINT) AS late_event_count,
    SUM(duplicate_event_count) AS duplicate_event_count,
    CAST(0 AS BIGINT) AS malformed_event_count,
    SUM(source_event_count) AS source_event_count
FROM session_funnel_enriched
GROUP BY
    window_start,
    window_end,
    category_code,
    price_tier,
    customer_state,
    seller_state;

INSERT INTO mart_funnel_1h_staging
SELECT
    window_start,
    window_end,
    category_code,
    price_tier,
    customer_state,
    seller_state,
    view_count,
    cart_count,
    purchase_count,
    view_session_count,
    cart_session_count,
    purchase_session_count,
    CASE
        WHEN view_count = 0 THEN CAST(NULL AS DOUBLE)
        ELSE CAST(cart_count AS DOUBLE) / view_count
    END AS view_to_cart_rate,
    CASE
        WHEN cart_count = 0 THEN CAST(NULL AS DOUBLE)
        ELSE CAST(purchase_count AS DOUBLE) / cart_count
    END AS cart_to_purchase_rate,
    CASE
        WHEN view_count = 0 THEN CAST(NULL AS DOUBLE)
        ELSE CAST(purchase_count AS DOUBLE) / view_count
    END AS view_to_purchase_rate,
    late_event_count,
    duplicate_event_count,
    malformed_event_count,
    source_event_count,
    CURRENT_TIMESTAMP AS built_at,
    DATE_FORMAT(window_start, 'yyyy-MM-dd') AS dt
FROM hourly_funnel_counts;
