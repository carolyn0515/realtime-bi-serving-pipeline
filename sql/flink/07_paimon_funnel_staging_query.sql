SET 'execution.runtime-mode' = 'batch';
SET 'sql-client.execution.result-mode' = 'tableau';

CREATE CATALOG paimon WITH (
    'type' = 'paimon',
    'warehouse' = 'file:/warehouse/paimon'
);

USE CATALOG paimon;
USE lakehouse;

SELECT
    'session_funnel_staging' AS table_name,
    COUNT(*) AS row_count
FROM session_funnel_staging
UNION ALL
SELECT
    'mart_funnel_1h_staging' AS table_name,
    COUNT(*) AS row_count
FROM mart_funnel_1h_staging;

SELECT
    has_view,
    has_cart,
    has_purchase,
    COUNT(*) AS session_count
FROM session_funnel_staging
GROUP BY
    has_view,
    has_cart,
    has_purchase
ORDER BY
    has_view DESC,
    has_cart DESC,
    has_purchase DESC;

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
    view_to_purchase_rate
FROM mart_funnel_1h_staging
ORDER BY
    window_start,
    category_code,
    price_tier,
    customer_state,
    seller_state
LIMIT 20;

SELECT
    SUM(view_count) AS total_view_count,
    SUM(cart_count) AS total_cart_count,
    SUM(purchase_count) AS total_purchase_count,
    SUM(duplicate_event_count) AS duplicate_event_count,
    SUM(malformed_event_count) AS malformed_event_count
FROM mart_funnel_1h_staging;
