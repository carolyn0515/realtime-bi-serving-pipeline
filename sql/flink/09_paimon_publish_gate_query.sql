SET 'execution.runtime-mode' = 'batch';
SET 'sql-client.execution.result-mode' = 'tableau';

CREATE CATALOG paimon WITH (
    'type' = 'paimon',
    'warehouse' = 'file:/warehouse/paimon'
);

USE CATALOG paimon;
USE lakehouse;

SELECT
    'staging' AS layer,
    COUNT(*) AS row_count
FROM mart_funnel_1h_staging
UNION ALL
SELECT
    'dq_audit' AS layer,
    COUNT(*) AS row_count
FROM dq_audit_result
UNION ALL
SELECT
    'published' AS layer,
    COUNT(*) AS row_count
FROM mart_funnel_1h_published;

SELECT
    dq_status,
    COALESCE(dq_error_reason, 'none') AS dq_error_reason,
    COUNT(*) AS row_count
FROM dq_audit_result
GROUP BY
    dq_status,
    COALESCE(dq_error_reason, 'none')
ORDER BY
    dq_status,
    row_count DESC,
    dq_error_reason;

SELECT
    MIN(published_at) AS first_published_at,
    MAX(published_at) AS latest_published_at,
    MIN(window_start) AS min_window_start,
    MAX(window_end) AS max_window_end,
    COUNT(DISTINCT dq_run_id) AS dq_run_count
FROM mart_funnel_1h_published;

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
    view_to_cart_rate,
    cart_to_purchase_rate,
    view_to_purchase_rate,
    dq_status,
    severity
FROM mart_funnel_1h_published
ORDER BY
    window_start,
    category_code,
    price_tier,
    customer_state,
    seller_state
LIMIT 20;
