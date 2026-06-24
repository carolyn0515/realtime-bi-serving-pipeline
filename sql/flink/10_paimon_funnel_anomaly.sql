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

DROP TABLE IF EXISTS funnel_baseline_profile;
DROP TABLE IF EXISTS mart_funnel_1h_anomaly;

CREATE TABLE IF NOT EXISTS funnel_baseline_profile (
    baseline_scope STRING,
    category_code STRING,
    price_tier STRING,
    customer_state STRING,
    seller_state STRING,
    baseline_window_count BIGINT,
    baseline_view_count BIGINT,
    baseline_cart_count BIGINT,
    baseline_purchase_count BIGINT,
    baseline_view_to_cart_rate DOUBLE,
    baseline_cart_to_purchase_rate DOUBLE,
    baseline_view_to_purchase_rate DOUBLE,
    stddev_view_to_cart_rate DOUBLE,
    stddev_cart_to_purchase_rate DOUBLE,
    stddev_view_to_purchase_rate DOUBLE,
    built_at TIMESTAMP(3),
    dt STRING
) PARTITIONED BY (dt)
WITH (
    'bucket' = '-1',
    'file.format' = 'parquet',
    'snapshot.num-retained.min' = '10',
    'snapshot.num-retained.max' = '30'
);

CREATE TABLE IF NOT EXISTS mart_funnel_1h_anomaly (
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
    baseline_scope STRING,
    baseline_window_count BIGINT,
    baseline_view_count BIGINT,
    baseline_cart_count BIGINT,
    baseline_purchase_count BIGINT,
    baseline_view_to_cart_rate DOUBLE,
    baseline_cart_to_purchase_rate DOUBLE,
    baseline_view_to_purchase_rate DOUBLE,
    stddev_view_to_cart_rate DOUBLE,
    stddev_cart_to_purchase_rate DOUBLE,
    stddev_view_to_purchase_rate DOUBLE,
    view_to_cart_drop_rate DOUBLE,
    cart_to_purchase_drop_rate DOUBLE,
    view_to_purchase_drop_rate DOUBLE,
    baseline_rate DOUBLE,
    rate_stddev DOUBLE,
    drop_rate DOUBLE,
    severity STRING,
    anomaly_stage STRING,
    scored_at TIMESTAMP(3),
    dt STRING
) PARTITIONED BY (dt)
WITH (
    'bucket' = '-1',
    'file.format' = 'parquet',
    'snapshot.num-retained.min' = '10',
    'snapshot.num-retained.max' = '30'
);

CREATE TEMPORARY VIEW baseline_exact AS
SELECT
    'exact_segment' AS baseline_scope,
    category_code,
    price_tier,
    customer_state,
    seller_state,
    COUNT(*) AS baseline_window_count,
    SUM(view_count) AS baseline_view_count,
    SUM(cart_count) AS baseline_cart_count,
    SUM(purchase_count) AS baseline_purchase_count,
    AVG(view_to_cart_rate) AS baseline_view_to_cart_rate,
    AVG(cart_to_purchase_rate) AS baseline_cart_to_purchase_rate,
    AVG(view_to_purchase_rate) AS baseline_view_to_purchase_rate,
    STDDEV_POP(view_to_cart_rate) AS stddev_view_to_cart_rate,
    STDDEV_POP(cart_to_purchase_rate) AS stddev_cart_to_purchase_rate,
    STDDEV_POP(view_to_purchase_rate) AS stddev_view_to_purchase_rate
FROM mart_funnel_1h_published
GROUP BY
    category_code,
    price_tier,
    customer_state,
    seller_state;

CREATE TEMPORARY VIEW baseline_category_price AS
SELECT
    'category_price' AS baseline_scope,
    category_code,
    price_tier,
    CAST(NULL AS STRING) AS customer_state,
    CAST(NULL AS STRING) AS seller_state,
    COUNT(*) AS baseline_window_count,
    SUM(view_count) AS baseline_view_count,
    SUM(cart_count) AS baseline_cart_count,
    SUM(purchase_count) AS baseline_purchase_count,
    AVG(view_to_cart_rate) AS baseline_view_to_cart_rate,
    AVG(cart_to_purchase_rate) AS baseline_cart_to_purchase_rate,
    AVG(view_to_purchase_rate) AS baseline_view_to_purchase_rate,
    STDDEV_POP(view_to_cart_rate) AS stddev_view_to_cart_rate,
    STDDEV_POP(cart_to_purchase_rate) AS stddev_cart_to_purchase_rate,
    STDDEV_POP(view_to_purchase_rate) AS stddev_view_to_purchase_rate
FROM mart_funnel_1h_published
GROUP BY
    category_code,
    price_tier;

CREATE TEMPORARY VIEW baseline_global AS
SELECT
    'global' AS baseline_scope,
    CAST(NULL AS STRING) AS category_code,
    CAST(NULL AS STRING) AS price_tier,
    CAST(NULL AS STRING) AS customer_state,
    CAST(NULL AS STRING) AS seller_state,
    COUNT(*) AS baseline_window_count,
    SUM(view_count) AS baseline_view_count,
    SUM(cart_count) AS baseline_cart_count,
    SUM(purchase_count) AS baseline_purchase_count,
    AVG(view_to_cart_rate) AS baseline_view_to_cart_rate,
    AVG(cart_to_purchase_rate) AS baseline_cart_to_purchase_rate,
    AVG(view_to_purchase_rate) AS baseline_view_to_purchase_rate,
    STDDEV_POP(view_to_cart_rate) AS stddev_view_to_cart_rate,
    STDDEV_POP(cart_to_purchase_rate) AS stddev_cart_to_purchase_rate,
    STDDEV_POP(view_to_purchase_rate) AS stddev_view_to_purchase_rate
FROM mart_funnel_1h_published;

INSERT INTO funnel_baseline_profile
SELECT
    baseline_scope,
    category_code,
    price_tier,
    customer_state,
    seller_state,
    baseline_window_count,
    baseline_view_count,
    baseline_cart_count,
    baseline_purchase_count,
    baseline_view_to_cart_rate,
    baseline_cart_to_purchase_rate,
    baseline_view_to_purchase_rate,
    stddev_view_to_cart_rate,
    stddev_cart_to_purchase_rate,
    stddev_view_to_purchase_rate,
    CURRENT_TIMESTAMP AS built_at,
    DATE_FORMAT(CURRENT_TIMESTAMP, 'yyyy-MM-dd') AS dt
FROM baseline_exact
UNION ALL
SELECT
    baseline_scope,
    category_code,
    price_tier,
    customer_state,
    seller_state,
    baseline_window_count,
    baseline_view_count,
    baseline_cart_count,
    baseline_purchase_count,
    baseline_view_to_cart_rate,
    baseline_cart_to_purchase_rate,
    baseline_view_to_purchase_rate,
    stddev_view_to_cart_rate,
    stddev_cart_to_purchase_rate,
    stddev_view_to_purchase_rate,
    CURRENT_TIMESTAMP AS built_at,
    DATE_FORMAT(CURRENT_TIMESTAMP, 'yyyy-MM-dd') AS dt
FROM baseline_category_price
UNION ALL
SELECT
    baseline_scope,
    category_code,
    price_tier,
    customer_state,
    seller_state,
    baseline_window_count,
    baseline_view_count,
    baseline_cart_count,
    baseline_purchase_count,
    baseline_view_to_cart_rate,
    baseline_cart_to_purchase_rate,
    baseline_view_to_purchase_rate,
    stddev_view_to_cart_rate,
    stddev_cart_to_purchase_rate,
    stddev_view_to_purchase_rate,
    CURRENT_TIMESTAMP AS built_at,
    DATE_FORMAT(CURRENT_TIMESTAMP, 'yyyy-MM-dd') AS dt
FROM baseline_global;

CREATE TEMPORARY VIEW published_with_baseline AS
SELECT
    p.*,
    CASE
        WHEN exact_b.baseline_window_count >= 3 AND exact_b.baseline_view_count >= 10 THEN exact_b.baseline_scope
        WHEN cp_b.baseline_window_count >= 3 AND cp_b.baseline_view_count >= 10 THEN cp_b.baseline_scope
        ELSE global_b.baseline_scope
    END AS selected_baseline_scope,
    CASE
        WHEN exact_b.baseline_window_count >= 3 AND exact_b.baseline_view_count >= 10 THEN exact_b.baseline_window_count
        WHEN cp_b.baseline_window_count >= 3 AND cp_b.baseline_view_count >= 10 THEN cp_b.baseline_window_count
        ELSE global_b.baseline_window_count
    END AS selected_baseline_window_count,
    CASE
        WHEN exact_b.baseline_window_count >= 3 AND exact_b.baseline_view_count >= 10 THEN exact_b.baseline_view_count
        WHEN cp_b.baseline_window_count >= 3 AND cp_b.baseline_view_count >= 10 THEN cp_b.baseline_view_count
        ELSE global_b.baseline_view_count
    END AS selected_baseline_view_count,
    CASE
        WHEN exact_b.baseline_window_count >= 3 AND exact_b.baseline_view_count >= 10 THEN exact_b.baseline_cart_count
        WHEN cp_b.baseline_window_count >= 3 AND cp_b.baseline_view_count >= 10 THEN cp_b.baseline_cart_count
        ELSE global_b.baseline_cart_count
    END AS selected_baseline_cart_count,
    CASE
        WHEN exact_b.baseline_window_count >= 3 AND exact_b.baseline_view_count >= 10 THEN exact_b.baseline_purchase_count
        WHEN cp_b.baseline_window_count >= 3 AND cp_b.baseline_view_count >= 10 THEN cp_b.baseline_purchase_count
        ELSE global_b.baseline_purchase_count
    END AS selected_baseline_purchase_count,
    CASE
        WHEN exact_b.baseline_window_count >= 3 AND exact_b.baseline_view_count >= 10 THEN exact_b.baseline_view_to_cart_rate
        WHEN cp_b.baseline_window_count >= 3 AND cp_b.baseline_view_count >= 10 THEN cp_b.baseline_view_to_cart_rate
        ELSE global_b.baseline_view_to_cart_rate
    END AS selected_baseline_view_to_cart_rate,
    CASE
        WHEN exact_b.baseline_window_count >= 3 AND exact_b.baseline_view_count >= 10 THEN exact_b.baseline_cart_to_purchase_rate
        WHEN cp_b.baseline_window_count >= 3 AND cp_b.baseline_view_count >= 10 THEN cp_b.baseline_cart_to_purchase_rate
        ELSE global_b.baseline_cart_to_purchase_rate
    END AS selected_baseline_cart_to_purchase_rate,
    CASE
        WHEN exact_b.baseline_window_count >= 3 AND exact_b.baseline_view_count >= 10 THEN exact_b.baseline_view_to_purchase_rate
        WHEN cp_b.baseline_window_count >= 3 AND cp_b.baseline_view_count >= 10 THEN cp_b.baseline_view_to_purchase_rate
        ELSE global_b.baseline_view_to_purchase_rate
    END AS selected_baseline_view_to_purchase_rate,
    CASE
        WHEN exact_b.baseline_window_count >= 3 AND exact_b.baseline_view_count >= 10 THEN exact_b.stddev_view_to_cart_rate
        WHEN cp_b.baseline_window_count >= 3 AND cp_b.baseline_view_count >= 10 THEN cp_b.stddev_view_to_cart_rate
        ELSE global_b.stddev_view_to_cart_rate
    END AS selected_stddev_view_to_cart_rate,
    CASE
        WHEN exact_b.baseline_window_count >= 3 AND exact_b.baseline_view_count >= 10 THEN exact_b.stddev_cart_to_purchase_rate
        WHEN cp_b.baseline_window_count >= 3 AND cp_b.baseline_view_count >= 10 THEN cp_b.stddev_cart_to_purchase_rate
        ELSE global_b.stddev_cart_to_purchase_rate
    END AS selected_stddev_cart_to_purchase_rate,
    CASE
        WHEN exact_b.baseline_window_count >= 3 AND exact_b.baseline_view_count >= 10 THEN exact_b.stddev_view_to_purchase_rate
        WHEN cp_b.baseline_window_count >= 3 AND cp_b.baseline_view_count >= 10 THEN cp_b.stddev_view_to_purchase_rate
        ELSE global_b.stddev_view_to_purchase_rate
    END AS selected_stddev_view_to_purchase_rate
FROM mart_funnel_1h_published p
LEFT JOIN baseline_exact exact_b
    ON p.category_code = exact_b.category_code
   AND p.price_tier = exact_b.price_tier
   AND p.customer_state = exact_b.customer_state
   AND p.seller_state = exact_b.seller_state
LEFT JOIN baseline_category_price cp_b
    ON p.category_code = cp_b.category_code
   AND p.price_tier = cp_b.price_tier
CROSS JOIN baseline_global global_b;

CREATE TEMPORARY VIEW anomaly_scored AS
SELECT
    *,
    CASE
        WHEN selected_baseline_view_to_cart_rate IS NULL OR selected_baseline_view_to_cart_rate <= 0 THEN CAST(NULL AS DOUBLE)
        ELSE (selected_baseline_view_to_cart_rate - view_to_cart_rate) / selected_baseline_view_to_cart_rate
    END AS view_to_cart_drop_rate,
    CASE
        WHEN selected_baseline_cart_to_purchase_rate IS NULL OR selected_baseline_cart_to_purchase_rate <= 0 OR cart_to_purchase_rate IS NULL THEN CAST(NULL AS DOUBLE)
        ELSE (selected_baseline_cart_to_purchase_rate - cart_to_purchase_rate) / selected_baseline_cart_to_purchase_rate
    END AS cart_to_purchase_drop_rate,
    CASE
        WHEN selected_baseline_view_to_purchase_rate IS NULL OR selected_baseline_view_to_purchase_rate <= 0 THEN CAST(NULL AS DOUBLE)
        ELSE (selected_baseline_view_to_purchase_rate - view_to_purchase_rate) / selected_baseline_view_to_purchase_rate
    END AS view_to_purchase_drop_rate
FROM published_with_baseline;

CREATE TEMPORARY VIEW anomaly_selected AS
SELECT
    *,
    CASE
        WHEN view_to_purchase_drop_rate IS NOT NULL
         AND (view_to_cart_drop_rate IS NULL OR view_to_purchase_drop_rate >= view_to_cart_drop_rate)
         AND (cart_to_purchase_drop_rate IS NULL OR view_to_purchase_drop_rate >= cart_to_purchase_drop_rate)
            THEN 'view_to_purchase'
        WHEN view_to_cart_drop_rate IS NOT NULL
         AND (cart_to_purchase_drop_rate IS NULL OR view_to_cart_drop_rate >= cart_to_purchase_drop_rate)
            THEN 'view_to_cart'
        WHEN cart_to_purchase_drop_rate IS NOT NULL
            THEN 'cart_to_purchase'
        ELSE NULL
    END AS selected_anomaly_stage,
    GREATEST(
        COALESCE(view_to_cart_drop_rate, -1.0),
        COALESCE(cart_to_purchase_drop_rate, -1.0),
        COALESCE(view_to_purchase_drop_rate, -1.0)
    ) AS selected_drop_rate
FROM anomaly_scored;

INSERT INTO mart_funnel_1h_anomaly
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
    published_at,
    dq_status,
    dq_run_id,
    selected_baseline_scope AS baseline_scope,
    selected_baseline_window_count AS baseline_window_count,
    selected_baseline_view_count AS baseline_view_count,
    selected_baseline_cart_count AS baseline_cart_count,
    selected_baseline_purchase_count AS baseline_purchase_count,
    selected_baseline_view_to_cart_rate AS baseline_view_to_cart_rate,
    selected_baseline_cart_to_purchase_rate AS baseline_cart_to_purchase_rate,
    selected_baseline_view_to_purchase_rate AS baseline_view_to_purchase_rate,
    selected_stddev_view_to_cart_rate AS stddev_view_to_cart_rate,
    selected_stddev_cart_to_purchase_rate AS stddev_cart_to_purchase_rate,
    selected_stddev_view_to_purchase_rate AS stddev_view_to_purchase_rate,
    view_to_cart_drop_rate,
    cart_to_purchase_drop_rate,
    view_to_purchase_drop_rate,
    CASE
        WHEN view_count < 10 THEN CAST(NULL AS DOUBLE)
        WHEN selected_anomaly_stage = 'view_to_purchase' THEN selected_baseline_view_to_purchase_rate
        WHEN selected_anomaly_stage = 'view_to_cart' THEN selected_baseline_view_to_cart_rate
        WHEN selected_anomaly_stage = 'cart_to_purchase' THEN selected_baseline_cart_to_purchase_rate
        ELSE CAST(NULL AS DOUBLE)
    END AS baseline_rate,
    CASE
        WHEN view_count < 10 THEN CAST(NULL AS DOUBLE)
        WHEN selected_anomaly_stage = 'view_to_purchase' THEN selected_stddev_view_to_purchase_rate
        WHEN selected_anomaly_stage = 'view_to_cart' THEN selected_stddev_view_to_cart_rate
        WHEN selected_anomaly_stage = 'cart_to_purchase' THEN selected_stddev_cart_to_purchase_rate
        ELSE CAST(NULL AS DOUBLE)
    END AS rate_stddev,
    CASE
        WHEN view_count < 10 OR selected_drop_rate < 0 THEN CAST(NULL AS DOUBLE)
        ELSE selected_drop_rate
    END AS drop_rate,
    CASE
        WHEN view_count < 10 THEN 'normal'
        WHEN selected_drop_rate >= 0.50 THEN 'critical'
        WHEN selected_drop_rate >= 0.25 THEN 'warning'
        ELSE 'normal'
    END AS severity,
    CASE
        WHEN view_count >= 10 AND selected_drop_rate >= 0.25 THEN selected_anomaly_stage
        ELSE CAST(NULL AS STRING)
    END AS anomaly_stage,
    CURRENT_TIMESTAMP AS scored_at,
    dt
FROM anomaly_selected;
