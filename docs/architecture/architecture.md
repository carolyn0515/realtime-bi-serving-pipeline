# Architecture

```text
Olist CSV
  -> UX Log Generator
  -> Kafka ux-events
  -> Flink Streaming
      -> Paimon ux_events_bronze
      -> Paimon invalid_ux_events
      -> Paimon ux_events_clean
      -> Paimon mart_funnel_Xm_staging
  -> DQ Audit
      -> Paimon audit_result
      -> Paimon mart_funnel_Xm_published
  -> Spark Batch Baseline
      -> Iceberg funnel_hourly_baseline
  -> StarRocks External Catalog
      -> Dashboard Views
  -> OpenMetadata Lineage
```

## Design Principle

BI must read only from published marts. Staging data can be fast, but published data must be trusted.
