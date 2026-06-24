# Architecture

## Current Implemented Flow

```text
Olist CSV
  -> UX Log Generator
  -> Kafka ux-events
  -> Flink SQL
      -> Paimon ux_events_bronze
      -> Paimon ux_events_clean
      -> Paimon ux_events_invalid
      -> Paimon session_funnel_staging
      -> Paimon mart_funnel_1h_staging
      -> Paimon dq_audit_result
      -> Paimon mart_funnel_1h_published
      -> Paimon funnel_baseline_profile
      -> Paimon mart_funnel_1h_anomaly
  -> StarRocks Paimon external catalog
  -> StarRocks serving views
  -> Dashboard evidence export
```

## Design Principle

BI must read only from serving views backed by DQ-passed published/anomaly marts.

Staging data can be fast and provisional. Published and anomaly-scored data must be trusted, auditable, and reproducible.

## Layer Responsibilities

### UX Log Generator

Transforms Olist order data into synthetic customer behavior events:

```text
view -> cart -> purchase
```

The raw stream keeps customer behavior fields only. BI-oriented labels are derived later.

### Kafka

Stores append-only UX events in `ux-events`.

The event key is `session_id`, which keeps related behavior events partitioned consistently for local demos.

### Flink

Reads Kafka JSON records with event-time parsing and writes Paimon tables.

### Paimon

Stores the lakehouse layers:

- `ux_events_bronze`: raw event append log with Kafka metadata
- `ux_events_clean`: valid events
- `ux_events_invalid`: rejected events with validation reason
- `session_funnel_staging`: session-level funnel state
- `mart_funnel_1h_staging`: hourly view-start cohort funnel metrics
- `dq_audit_result`: publish-gate audit history
- `mart_funnel_1h_published`: BI-eligible rows
- `funnel_baseline_profile`: explainable baseline profiles
- `mart_funnel_1h_anomaly`: anomaly-scored BI mart

### StarRocks

Exposes Paimon data through an external catalog:

```text
paimon_lakehouse.lakehouse.mart_funnel_1h_anomaly
```

BI-facing views:

```text
bi_serving.v_funnel_health
bi_serving.v_anomaly_watchlist
```

### Dashboard Evidence

Exports StarRocks serving view results to:

```text
data/generated/starrocks_dashboard/dashboard.html
data/generated/starrocks_dashboard/dashboard_data.json
```

## Important Design Decisions

### Session-Cohort Funnel Mart

The hourly funnel mart uses the session's `view_ts` as the window anchor. This prevents false conversion-rate distortion when a user views in one hour and carts or purchases in a later hour.

### Publish Gate

Only DQ `PASS` rows move from staging to published. Failed rows stay in the audit table with explicit reasons.

### Baseline Fallback

Anomaly scoring uses:

```text
exact_segment -> category_price -> global
```

Small current windows are not promoted to alerts. This avoids overconfident anomaly labels from sparse data.

## Future Extensions

- Add anomaly injection scenarios.
- Add OpenMetadata lineage.
- Add a richer dashboard or BI tool integration.
- Add operational recovery demos for replay and publish rollback.
