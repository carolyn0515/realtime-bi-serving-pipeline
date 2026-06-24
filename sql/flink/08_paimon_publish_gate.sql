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

DROP TABLE IF EXISTS dq_audit_result;
DROP TABLE IF EXISTS mart_funnel_1h_published;

CREATE TABLE IF NOT EXISTS dq_audit_result (
    dq_run_id STRING,
    checked_at TIMESTAMP(3),
    source_table STRING,
    target_table STRING,
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    category_code STRING,
    price_tier STRING,
    customer_state STRING,
    seller_state STRING,
    source_event_count BIGINT,
    late_event_count BIGINT,
    duplicate_event_count BIGINT,
    malformed_event_count BIGINT,
    late_event_ratio DOUBLE,
    dq_status STRING,
    dq_error_reason STRING,
    dt STRING
) PARTITIONED BY (dt)
WITH (
    'bucket' = '-1',
    'file.format' = 'parquet',
    'snapshot.num-retained.min' = '10',
    'snapshot.num-retained.max' = '30'
);

CREATE TABLE IF NOT EXISTS mart_funnel_1h_published (
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
    published_at TIMESTAMP(3),
    dq_status STRING,
    dq_run_id STRING,
    baseline_rate DOUBLE,
    rate_stddev DOUBLE,
    drop_rate DOUBLE,
    severity STRING,
    anomaly_stage STRING,
    dt STRING
) PARTITIONED BY (dt)
WITH (
    'bucket' = '-1',
    'file.format' = 'parquet',
    'snapshot.num-retained.min' = '10',
    'snapshot.num-retained.max' = '30'
);

CREATE TEMPORARY VIEW dq_evaluated AS
SELECT
    CONCAT('dq_', DATE_FORMAT(CURRENT_TIMESTAMP, 'yyyyMMddHHmmss')) AS dq_run_id,
    CURRENT_TIMESTAMP AS checked_at,
    'mart_funnel_1h_staging' AS source_table,
    'mart_funnel_1h_published' AS target_table,
    *,
    CASE
        WHEN source_event_count = 0 THEN CAST(NULL AS DOUBLE)
        ELSE CAST(late_event_count AS DOUBLE) / source_event_count
    END AS late_event_ratio,
    CASE
        WHEN window_start IS NULL OR window_end IS NULL THEN 'missing_window'
        WHEN window_end <= window_start THEN 'invalid_window_range'
        WHEN category_code IS NULL OR TRIM(category_code) = '' THEN 'missing_category_code'
        WHEN price_tier IS NULL OR price_tier NOT IN ('low', 'mid', 'high') THEN 'invalid_price_tier'
        WHEN customer_state IS NULL OR TRIM(customer_state) = '' THEN 'missing_customer_state'
        WHEN seller_state IS NULL OR TRIM(seller_state) = '' THEN 'missing_seller_state'
        WHEN source_event_count IS NULL OR source_event_count <= 0 THEN 'empty_window'
        WHEN view_count < 0 OR cart_count < 0 OR purchase_count < 0 THEN 'negative_event_count'
        WHEN view_session_count < 0 OR cart_session_count < 0 OR purchase_session_count < 0 THEN 'negative_session_count'
        WHEN view_count + cart_count + purchase_count <> source_event_count THEN 'source_count_mismatch'
        WHEN malformed_event_count > 0 THEN 'malformed_events_present'
        WHEN duplicate_event_count > 0 THEN 'duplicate_events_present'
        WHEN source_event_count > 0 AND CAST(late_event_count AS DOUBLE) / source_event_count > 0.05 THEN 'late_event_ratio_exceeded'
        WHEN view_to_cart_rate IS NOT NULL AND (view_to_cart_rate < 0 OR view_to_cart_rate > 1) THEN 'invalid_view_to_cart_rate'
        WHEN cart_to_purchase_rate IS NOT NULL AND (cart_to_purchase_rate < 0 OR cart_to_purchase_rate > 1) THEN 'invalid_cart_to_purchase_rate'
        WHEN view_to_purchase_rate IS NOT NULL AND (view_to_purchase_rate < 0 OR view_to_purchase_rate > 1) THEN 'invalid_view_to_purchase_rate'
        ELSE NULL
    END AS dq_error_reason
FROM mart_funnel_1h_staging;

CREATE TEMPORARY VIEW dq_with_status AS
SELECT
    *,
    CASE
        WHEN dq_error_reason IS NULL THEN 'PASS'
        ELSE 'FAIL'
    END AS dq_status
FROM dq_evaluated;

INSERT INTO dq_audit_result
SELECT
    dq_run_id,
    checked_at,
    source_table,
    target_table,
    window_start,
    window_end,
    category_code,
    price_tier,
    customer_state,
    seller_state,
    source_event_count,
    late_event_count,
    duplicate_event_count,
    malformed_event_count,
    late_event_ratio,
    dq_status,
    dq_error_reason,
    dt
FROM dq_with_status;

INSERT INTO mart_funnel_1h_published
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
    view_to_cart_rate,
    cart_to_purchase_rate,
    view_to_purchase_rate,
    late_event_count,
    duplicate_event_count,
    malformed_event_count,
    source_event_count,
    built_at,
    checked_at AS published_at,
    dq_status,
    dq_run_id,
    CAST(NULL AS DOUBLE) AS baseline_rate,
    CAST(NULL AS DOUBLE) AS rate_stddev,
    CAST(NULL AS DOUBLE) AS drop_rate,
    'normal' AS severity,
    CAST(NULL AS STRING) AS anomaly_stage,
    dt
FROM dq_with_status
WHERE dq_status = 'PASS';
