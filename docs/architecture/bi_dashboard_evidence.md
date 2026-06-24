# BI Dashboard Evidence

## Role

The dashboard evidence export shows the final serving contract from StarRocks.

```text
StarRocks bi_serving.v_funnel_health
  -> data/generated/starrocks_dashboard/dashboard_data.json
  -> data/generated/starrocks_dashboard/dashboard.html
```

This artifact is intentionally lightweight. It proves that BI-facing data is queried from StarRocks serving views, not directly from Kafka, Flink, staging tables, or raw Paimon layers.

## Source Views

`bi_serving.v_funnel_health`

- complete final funnel health surface
- includes DQ, publish, baseline, and anomaly columns

`bi_serving.v_anomaly_watchlist`

- warning and critical rows only
- may be empty when the sample is healthy or too sparse for alerting

## Exported Files

`dashboard_data.json`

- machine-readable evidence for summary cards and tables

`dashboard.html`

- static dashboard preview
- can be opened directly in a browser
- useful for portfolio screenshots

## Why Static HTML First

A full BI tool can be added later, but the first evidence artifact should be easy to regenerate and inspect.

The static export keeps the focus on the data serving contract:

- Paimon stores trusted mart data.
- StarRocks exposes queryable BI views.
- Dashboard evidence reads from StarRocks.

## Completion Criteria

This stage is complete when:

- StarRocks serving views exist.
- exporter queries StarRocks successfully.
- `dashboard_data.json` is generated.
- `dashboard.html` is generated.
- summary counts match StarRocks query results.
