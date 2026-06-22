# Mart Grain

## Event Grain

One row represents one synthetic UX event.

Required identifiers:

- `event_id`
- `session_id`
- `user_id`
- `order_id`
- `order_item_id`
- `product_id`

Required time fields:

- `event_time`
- `ingested_at`

Required event fields:

- `event_type`
- `category_code`
- `price`
- `price_tier`
- `review_score`
- `review_tier`
- `freight_value`
- `freight_tier`
- `payment_type`
- `customer_state`
- `seller_state`

## Funnel Staging Mart Grain

One row represents one window and one diagnosis segment.

Primary key:

- `window_start`
- `window_end`
- `category_code`
- `price_tier`
- `review_tier`
- `freight_tier`
- `payment_type`
- `customer_state`
- `seller_state`

Measures:

- `view_count`
- `cart_count`
- `purchase_count`
- `view_to_cart_rate`
- `cart_to_purchase_rate`
- `view_to_purchase_rate`
- `late_event_count`
- `duplicate_event_count`
- `malformed_event_count`

## Published Mart Grain

The published mart uses the same grain as staging and adds trust and anomaly fields.

- `published_at`
- `dq_status`
- `dq_run_id`
- `baseline_rate`
- `rate_stddev`
- `drop_rate`
- `severity`
- `anomaly_stage`
