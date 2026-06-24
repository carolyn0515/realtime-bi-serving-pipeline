# Paimon Baseline And Anomaly Design

## Role

The anomaly layer compares published funnel metrics against an explainable baseline.

```text
mart_funnel_1h_published
  -> funnel_baseline_profile
  -> mart_funnel_1h_anomaly
```

This layer does not replace the publish gate. Only rows that already passed DQ are scored.

## Why Rule-Based Baseline

The project focuses on trustworthy real-time BI serving, not model-heavy anomaly detection.

For that reason, the first anomaly layer uses transparent baseline comparison:

- compute historical conversion rates from published rows
- choose a comparable baseline scope
- calculate drop rates
- classify severity with explicit thresholds

This makes the result easy to explain and audit.

## Baseline Fallback Hierarchy

Fine-grained segments can be sparse. A baseline based on one or two windows is not trustworthy.

The scoring query therefore uses this fallback order:

1. `exact_segment`: `category_code`, `price_tier`, `customer_state`, `seller_state`
2. `category_price`: `category_code`, `price_tier`
3. `global`: all published rows

The exact and category-price baselines are used only when:

- `baseline_window_count >= 3`
- `baseline_view_count >= 10`

Otherwise the row falls back to the broader baseline.

The current row is alerted only when:

- `view_count >= 10`

Rows below that threshold can still be scored internally, but they are not promoted to warning or critical anomalies. This avoids noisy alerts from tiny windows.

## Scored Metrics

The anomaly table keeps the published mart fields and adds:

- `baseline_scope`
- `baseline_window_count`
- `baseline_view_count`
- `baseline_cart_count`
- `baseline_purchase_count`
- baseline conversion rates
- conversion-rate standard deviations
- stage-specific drop rates
- selected `baseline_rate`
- selected `rate_stddev`
- selected `drop_rate`
- `severity`
- `anomaly_stage`
- `scored_at`

## Drop Rate

For each stage:

```text
drop_rate = (baseline_rate - current_rate) / baseline_rate
```

The calculation is skipped when the baseline is `NULL` or `<= 0`.

## Severity

Current thresholds:

- minimum current `view_count`: `10`
- `critical`: drop rate >= `0.50`
- `warning`: drop rate >= `0.25`
- `normal`: otherwise

When more than one stage drops, the selected `anomaly_stage` is the stage with the largest drop.

## Why This Is Defensible

This design avoids pretending that every segment has enough history.

Instead of forcing a noisy exact-segment comparison, the pipeline records which baseline scope was used. BI users can see whether an anomaly came from a precise segment baseline or a broader fallback baseline.

## Completion Criteria

This stage is complete when:

- `funnel_baseline_profile` is populated.
- every published row has one scored anomaly row.
- each scored row records which baseline scope was used.
- severity and anomaly stage are generated from explicit thresholds.
- scoring uses only DQ-passed published rows.

## Next Step

Expose the published/anomaly mart to serving:

```text
mart_funnel_1h_anomaly
  -> BI serving view
  -> dashboard sample
```
