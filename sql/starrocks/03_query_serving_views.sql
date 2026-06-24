SELECT
    COUNT(*) AS funnel_health_rows,
    MIN(window_start) AS min_window_start,
    MAX(window_end) AS max_window_end,
    COUNT(DISTINCT severity) AS severity_count
FROM bi_serving.v_funnel_health;

SELECT
    severity,
    COALESCE(anomaly_stage, 'none') AS anomaly_stage,
    COUNT(*) AS row_count
FROM bi_serving.v_funnel_health
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
    baseline_scope,
    COUNT(*) AS row_count,
    MIN(baseline_window_count) AS min_baseline_window_count,
    MAX(baseline_window_count) AS max_baseline_window_count
FROM bi_serving.v_funnel_health
GROUP BY baseline_scope
ORDER BY row_count DESC, baseline_scope;

SELECT
    window_start,
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
    baseline_scope,
    severity,
    anomaly_stage
FROM bi_serving.v_funnel_health
ORDER BY
    window_start,
    category_code,
    price_tier,
    customer_state,
    seller_state
LIMIT 20;

SELECT
    COUNT(*) AS watchlist_rows
FROM bi_serving.v_anomaly_watchlist;
