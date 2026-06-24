# Paimon Funnel Staging Design

## Role

The staging layer turns clean event logs into funnel-ready analytical facts.

```text
ux_events_clean
  -> session_funnel_staging
  -> mart_funnel_1h_staging
```

This is still not the published BI mart. Staging can be queried for development and audit, but BI should read from the published mart only after DQ checks pass.

## Session Funnel Staging

`session_funnel_staging` has one row per `session_id` and `product_id`.

It expands append-only events into ordered funnel state:

- `view_ts`
- `cart_ts`
- `purchase_ts`
- `has_view`
- `has_cart`
- `has_purchase`

This table is useful for checking whether event generation and streaming preserve behavior order before aggregation.

## Hourly Funnel Staging

`mart_funnel_1h_staging` has one row per one-hour view-start window and diagnosis segment.

The hourly window is based on `view_ts` from `session_funnel_staging`, not each individual event timestamp. This makes the rates cohort-like: among sessions that viewed in the window, how many eventually carted or purchased.

Current grain:

- `window_start`
- `window_end`
- `category_code`
- `price_tier`
- `customer_state`
- `seller_state`

Current measures:

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
- `source_event_count`

## Why The Hourly Mart Uses Session State

Counting raw events by each event's own timestamp can distort funnel rates. A user can view near the end of one hour, cart in the next hour, and purchase later. If each event is counted in its own hour, one window can show more carts than views.

For that reason, the hourly staging mart is built from `session_funnel_staging` and attributes the full session outcome to the view-start hour.

## Why Payment Type Is Not In The Hourly Grain Yet

In a real customer behavior log, `payment_type` is known only after purchase.

If hourly funnel conversion is grouped by `payment_type`, view and cart rows would mostly have `NULL` payment type while purchase rows would have actual payment values. That would split the funnel across different segments and make conversion rates misleading.

For that reason, payment-type diagnosis should be introduced later from checkout/purchase-specific facts, not from the generic view-to-purchase funnel grain.

## Derived Columns

`price_tier` is derived in staging:

```sql
CASE
    WHEN price < 50 THEN 'low'
    WHEN price < 150 THEN 'mid'
    ELSE 'high'
END
```

This keeps the raw stream close to customer behavior while still giving BI-friendly dimensions after the data passes the clean boundary.

## Completion Criteria

This stage is complete when:

- `session_funnel_staging` is created from `ux_events_clean`.
- `mart_funnel_1h_staging` is created from `ux_events_clean`.
- total staging event counts match clean event counts.
- conversion rates use safe division.
- staging remains separate from the published BI mart.

## Next Step

Add a DQ audit and publish gate:

```text
mart_funnel_1h_staging
  -> dq_audit_result
  -> mart_funnel_1h_published
```
