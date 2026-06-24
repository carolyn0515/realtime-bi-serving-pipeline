CREATE DATABASE IF NOT EXISTS bi_serving;

DROP VIEW IF EXISTS bi_serving.v_funnel_health;

CREATE VIEW bi_serving.v_funnel_health AS
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
    baseline_scope,
    baseline_window_count,
    baseline_view_count,
    baseline_view_to_cart_rate,
    baseline_cart_to_purchase_rate,
    baseline_view_to_purchase_rate,
    view_to_cart_drop_rate,
    cart_to_purchase_drop_rate,
    view_to_purchase_drop_rate,
    severity,
    anomaly_stage,
    dq_status,
    dq_run_id,
    published_at,
    scored_at,
    dt
FROM paimon_lakehouse.lakehouse.mart_funnel_1h_anomaly;

DROP VIEW IF EXISTS bi_serving.v_anomaly_watchlist;

CREATE VIEW bi_serving.v_anomaly_watchlist AS
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
    baseline_scope,
    drop_rate,
    severity,
    anomaly_stage,
    published_at,
    scored_at
FROM paimon_lakehouse.lakehouse.mart_funnel_1h_anomaly
WHERE severity IN ('warning', 'critical');
