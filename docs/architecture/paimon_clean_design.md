# Paimon Clean And Invalid Design

## Role

The clean layer is the first BI-candidate boundary.

```text
Paimon ux_events_bronze
  -> ux_events_clean
  -> ux_events_invalid
```

Bronze keeps the raw append log. Clean keeps only events that satisfy the minimum contract needed by downstream funnel processing. Invalid keeps rejected rows with a machine-readable reason so data quality failures are visible instead of silently dropped.

## Validation Scope

This layer checks whether a row is a coherent customer behavior event.

It does not enrich BI attributes such as price tier, review tier, or freight tier. Those belong later in staging or mart logic, after the raw stream has been made reliable.

Current validation rules:

- required identifiers exist: `event_id`, `session_id`, `user_id`, `product_id`
- `event_type` is one of `view`, `cart`, `purchase`
- `event_time` can be parsed into `event_ts`
- `price` is present and non-negative
- `category_code`, `customer_state`, and `seller_state` exist
- purchase events contain `order_id`, `order_item_id`, `payment_type`, and non-negative `shipping_fee`
- view/cart events do not carry purchase-only fields
- Kafka metadata exists: `kafka_partition`, `kafka_offset`

## Table Grain

`ux_events_clean`:

- one row per valid UX event
- same grain as Bronze
- partitioned by event date `dt`

`ux_events_invalid`:

- one row per rejected UX event
- same raw fields as Bronze
- adds `validation_error`
- adds `rejected_at`

## Why Keep Invalid Rows

Invalid rows are part of data reliability evidence.

For this project, the goal is not simply to produce a dashboard. The goal is to show that real-time data can be served to BI with an explicit quality boundary. Keeping rejected rows makes it possible to answer:

- what was rejected
- why it was rejected
- when the rejection happened
- which Kafka partition and offset produced the bad row

## Completion Criteria

This stage is complete when:

- `ux_events_clean` is created from Bronze.
- `ux_events_invalid` is created from Bronze.
- row counts show `bronze = clean + invalid`.
- invalid rows can be grouped by `validation_error`.
- clean rows preserve event-time and Kafka lineage columns.

## Next Step

After Clean works, add a staging layer that derives funnel-ready facts.

```text
ux_events_clean
  -> session_event_order
  -> hourly_funnel_staging
```
