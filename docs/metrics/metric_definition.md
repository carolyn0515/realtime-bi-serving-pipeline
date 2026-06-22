# Metric Definition

## Funnel Events

- `view`: A user viewed a product detail or product listing item.
- `cart`: A user added the viewed product to cart.
- `purchase`: A user completed purchase for the product interaction.

The source Olist data does not contain raw UX logs. These events are generated synthetically from order, item, product, payment, review, customer, and seller records.

## Core Counts

- `view_count`: Number of view events in the window.
- `cart_count`: Number of cart events in the window.
- `purchase_count`: Number of purchase events in the window.

## Core Rates

- `view_to_cart_rate = cart_count / view_count`
- `cart_to_purchase_rate = purchase_count / cart_count`
- `view_to_purchase_rate = purchase_count / view_count`

All rate calculations must use `NULLIF(denominator, 0)` or equivalent safe division.

## Trust Metrics

- `freshness_lag_seconds`: Difference between current processing time and latest published window end.
- `late_event_ratio`: Late event count divided by valid event count.
- `dq_status`: `PASS` or `FAIL`.
- `published_at`: Timestamp when the window became available to BI.

## Anomaly Metrics

- `baseline_rate`: Historical expected rate for the same comparable segment.
- `rate_stddev`: Historical standard deviation for the baseline segment.
- `drop_rate = (baseline_rate - current_rate) / baseline_rate`
- `severity`: `normal`, `warning`, or `critical`.
