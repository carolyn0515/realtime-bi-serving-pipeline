# Paimon Publish Gate Design

## Role

The publish gate separates fast staging metrics from BI-readable metrics.

```text
mart_funnel_1h_staging
  -> dq_audit_result
  -> mart_funnel_1h_published
```

Staging tables are allowed to be fast and provisional. Published tables are the trust boundary for BI.

## Tables

`dq_audit_result` records the result of every quality check.

Key fields:

- `dq_run_id`
- `checked_at`
- `source_table`
- `target_table`
- `window_start`
- `window_end`
- diagnosis segment fields
- count quality fields
- `late_event_ratio`
- `dq_status`
- `dq_error_reason`

`mart_funnel_1h_published` contains only rows that passed the audit.

It keeps the staging grain and adds:

- `published_at`
- `dq_status`
- `dq_run_id`
- `baseline_rate`
- `rate_stddev`
- `drop_rate`
- `severity`
- `anomaly_stage`

Baseline and anomaly fields are placeholders at this stage. They will be filled after the baseline/anomaly step is implemented.

## Current DQ Rules

A staging row fails the publish gate when:

- the window is missing or invalid
- required diagnosis dimensions are missing
- `price_tier` is not one of `low`, `mid`, `high`
- `source_event_count` is empty
- event or session counts are negative
- `view_count + cart_count + purchase_count` does not equal `source_event_count`
- malformed events are present
- duplicate events are present
- late event ratio is greater than `0.05`
- conversion rates fall outside `[0, 1]`

Rows that pass all rules are copied into `mart_funnel_1h_published`.

## Why Count Ordering Is Valid After Staging

The publish gate checks that conversion rates stay inside `[0, 1]`.

This is valid because `mart_funnel_1h_staging` is built from session state and attributed to the view-start hour. A session that views in one hour and purchases later is still counted in the original view cohort.

If the mart were built by counting each event in its own event-time hour, this rule would create false failures. The session staging boundary prevents that distortion.

## BI Contract

BI tools must query:

```text
mart_funnel_1h_published
```

They should not query:

```text
mart_funnel_1h_staging
```

This is the core trust boundary of the project.

## Completion Criteria

This stage is complete when:

- `dq_audit_result` is populated from staging.
- every staging row has one audit row.
- only `PASS` rows are copied into `mart_funnel_1h_published`.
- published rows include `dq_run_id` and `published_at`.
- BI-facing documentation points to published mart only.

## Next Step

Add a baseline and anomaly layer:

```text
mart_funnel_1h_published
  -> baseline comparison
  -> anomaly severity and diagnosis
```
