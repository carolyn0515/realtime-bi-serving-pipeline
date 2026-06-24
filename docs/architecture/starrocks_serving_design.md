# StarRocks Serving Design

## Role

StarRocks is the BI serving/query layer.

```text
Paimon mart_funnel_1h_anomaly
  -> StarRocks Paimon external catalog
  -> BI serving views
```

Paimon remains the trusted lakehouse storage and quality boundary. StarRocks provides the fast SQL serving surface that a dashboard or analyst can query.

## Why External Catalog

StarRocks supports Paimon external catalogs, which allow StarRocks to query Paimon data without ingesting it into StarRocks first.

This matches the project goal:

- Flink owns streaming writes.
- Paimon owns durable lakehouse tables.
- DQ and anomaly logic finish before serving.
- StarRocks reads the trusted result for BI.

For local development, the Paimon warehouse Docker volume is mounted into the StarRocks container as read-only.

## Local Catalog

```sql
CREATE EXTERNAL CATALOG paimon_lakehouse
PROPERTIES
(
    "type" = "paimon",
    "paimon.catalog.type" = "filesystem",
    "paimon.catalog.warehouse" = "file:/warehouse/paimon"
);
```

## Serving Views

`bi_serving.v_funnel_health` exposes the final anomaly-scored mart:

- window fields
- diagnosis dimensions
- funnel counts and rates
- baseline fields
- drop-rate fields
- severity and anomaly stage
- DQ and publish metadata

`bi_serving.v_anomaly_watchlist` exposes only warning and critical rows.

The watchlist can be empty for small or healthy samples. That is acceptable because anomaly labels require enough current volume.

## BI Contract

BI should query StarRocks views, not raw Paimon staging tables.

```text
bi_serving.v_funnel_health
bi_serving.v_anomaly_watchlist
```

The views are backed by:

```text
paimon_lakehouse.lakehouse.mart_funnel_1h_anomaly
```

## Completion Criteria

This stage is complete when:

- StarRocks starts locally.
- StarRocks creates a Paimon external catalog.
- StarRocks can list Paimon databases and tables.
- StarRocks can query `mart_funnel_1h_anomaly`.
- BI serving views return rows.

## Next Step

Add a dashboard sample or exported BI evidence:

```text
StarRocks serving views
  -> dashboard query examples
  -> screenshots or exported report artifacts
```
