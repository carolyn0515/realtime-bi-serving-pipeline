SET 'execution.runtime-mode' = 'batch';
SET 'sql-client.execution.result-mode' = 'tableau';

CREATE CATALOG paimon WITH (
    'type' = 'paimon',
    'warehouse' = 'file:/warehouse/paimon'
);

USE CATALOG paimon;
USE lakehouse;

SELECT
    'published' AS layer,
    COUNT(*) AS row_count
FROM mart_funnel_1h_published
UNION ALL
SELECT
    'baseline_profile' AS layer,
    COUNT(*) AS row_count
FROM funnel_baseline_profile
UNION ALL
SELECT
    'anomaly_scored' AS layer,
    COUNT(*) AS row_count
FROM mart_funnel_1h_anomaly;

SELECT
    baseline_scope,
    COUNT(*) AS scored_row_count,
    MIN(baseline_window_count) AS min_baseline_window_count,
    MAX(baseline_window_count) AS max_baseline_window_count
FROM mart_funnel_1h_anomaly
GROUP BY baseline_scope
ORDER BY scored_row_count DESC, baseline_scope;

SELECT
    severity,
    COALESCE(anomaly_stage, 'none') AS anomaly_stage,
    COUNT(*) AS row_count
FROM mart_funnel_1h_anomaly
GROUP BY
    severity,
    COALESCE(anomaly_stage, 'none')
ORDER BY
    CASE severity
        WHEN 'critical' THEN 1
        WHEN 'warning' THEN 2
        ELSE 3
    END,
    row_count DESC,
    anomaly_stage;

SELECT
    window_start,
    category_code,
    price_tier,
    customer_state,
    seller_state,
    view_count,
    cart_count,
    purchase_count,
    baseline_scope,
    view_to_cart_rate,
    baseline_view_to_cart_rate,
    view_to_cart_drop_rate,
    cart_to_purchase_rate,
    baseline_cart_to_purchase_rate,
    cart_to_purchase_drop_rate,
    view_to_purchase_rate,
    baseline_view_to_purchase_rate,
    view_to_purchase_drop_rate,
    severity,
    anomaly_stage
FROM mart_funnel_1h_anomaly
ORDER BY
    CASE severity
        WHEN 'critical' THEN 1
        WHEN 'warning' THEN 2
        ELSE 3
    END,
    drop_rate DESC NULLS LAST,
    window_start
LIMIT 20;

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
    baseline_view_to_purchase_rate
FROM funnel_baseline_profile
ORDER BY
    baseline_scope,
    baseline_window_count DESC,
    baseline_view_count DESC
LIMIT 20;
