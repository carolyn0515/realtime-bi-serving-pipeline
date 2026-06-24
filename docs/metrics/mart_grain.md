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
- `event_ts`
- `emitted_at`

Required event fields:

- `event_type`
- `category_code`
- `price`
- `payment_type`
- `customer_state`
- `seller_state`

Purchase-only fields:

- `order_id`
- `order_item_id`
- `payment_type`
- `shipping_fee`

Operational fields:

- `kafka_partition`
- `kafka_offset`
- `kafka_timestamp`

## Session Funnel Staging Grain

One row represents one session and one product.

Primary key candidate:

- `session_id`
- `product_id`

Measures and state fields:

- `view_ts`
- `cart_ts`
- `purchase_ts`
- `has_view`
- `has_cart`
- `has_purchase`
- `source_event_count`
- `duplicate_event_count`

## Funnel Staging Mart Grain

One row represents one window and one diagnosis segment.

Primary key:

- `window_start`
- `window_end`
- `category_code`
- `price_tier`
- `customer_state`
- `seller_state`

Measures:

- `view_count`
- `cart_count`
- `purchase_count`
- `view_session_count`
- `cart_session_count`
- `purchase_session_count`
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
