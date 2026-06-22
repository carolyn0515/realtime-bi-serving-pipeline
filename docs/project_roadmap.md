# Project Roadmap

## 1. Project Foundation

- Define the repository layout.
- Keep the raw Kaggle Olist CSV files outside the repo in `../archive`.
- Document the project goal, data flow, and implementation boundaries.

## 2. Olist Source Profiling

- Inspect all source CSV files and document each table grain.
- Identify join keys across orders, order items, products, payments, reviews, customers, and sellers.
- Decide which source columns become UX event dimensions.

## 3. Metric And Mart Design

- Define the `view -> cart -> purchase` funnel.
- Define event schema, session rules, and event-time semantics.
- Define mart grain for health, timeline, diagnosis, and data trust views.
- Write the first versions of metric definitions and diagnosis reason tree.

## 4. UX Log Generator

- Build joined interaction records from Olist source tables.
- Generate synthetic `view`, `cart`, and `purchase` events.
- Support repeatable random seeds.
- Support traffic profiles: low, medium, and high.
- Support anomaly injection by category, price tier, review tier, freight tier, payment type, customer state, and seller state.
- Support late, duplicate, and malformed event injection.
- Write JSONL samples before connecting Kafka.

## 5. Window Size Experiment

- Run local Python experiments before deploying streaming infrastructure.
- Compare candidate window sizes.
- Measure detection latency, false positive rate, and rate CV.
- Decide Trust Window and, if needed, Early Warning Window.
- Record the result as an ADR.

## 6. Local Full-Stack Infrastructure

- Add Docker Compose for Kafka, Flink, Spark, StarRocks, and OpenMetadata.
- Configure local warehouses for Paimon and Iceberg.
- Add basic health checks and startup scripts.

## 7. Kafka Ingestion

- Create the `ux-events` topic.
- Publish generated UX events into Kafka.
- Validate message schema, partition key, and event timestamp behavior.

## 8. Flink Bronze And Clean Layers

- Read Kafka events with event time and watermarking.
- Write raw events to Paimon bronze.
- Route malformed and late events to invalid event tables.
- Normalize valid events into the clean layer.

## 9. Realtime Funnel Staging Mart

- Aggregate clean events into windowed funnel metrics.
- Write staging mart rows into Paimon primary-key tables.
- Keep staging separate from BI-serving published marts.

## 10. DQ Audit And Publish Gate

- Run window-level data quality checks.
- Record audit results for every window.
- Publish only DQ PASS windows into the published mart.
- Keep the previous published state when DQ FAIL occurs.
- Refresh StarRocks metadata after publish.

## 11. Batch Baseline

- Calculate historical baselines using Spark.
- Exclude DQ-failed and volume-outlier periods.
- Store baseline rates, standard deviations, and sample counts in Iceberg.
- Track Iceberg snapshot IDs for rollback.

## 12. Anomaly Detection

- Compare published window rates with Iceberg baselines.
- Assign `normal`, `warning`, and `critical` severities.
- Classify anomaly stages such as `view_to_cart_drop`, `cart_to_purchase_drop`, and `data_quality_issue`.
- Calculate segment contribution for diagnosis.

## 13. StarRocks BI Serving

- Connect Paimon and Iceberg external catalogs.
- Create dashboard-facing views.
- Promote repeated dashboard queries to materialized views when needed.

## 14. Dashboard

- Build Funnel Health.
- Build Funnel Timeline.
- Build Funnel Diagnosis.
- Build Data Trust Status.
- Build Pipeline Ops Status.

## 15. OpenMetadata Lineage

- Register source topics, streaming jobs, lakehouse tables, serving views, and dashboard assets.
- Add ownership, descriptions, and DQ rule metadata.
- Capture lineage evidence for the portfolio.

## 16. Operations And Recovery

- Document checkpoint recovery.
- Document Kafka replay.
- Document staging mart recomputation.
- Document published mart rollback.
- Document Iceberg baseline rollback.
- Document StarRocks metadata refresh recovery.

## 17. Demo Scenarios

- Normal traffic.
- Conversion drop with DQ PASS.
- Late-event spike with DQ FAIL.
- Baseline update and rollback.
- BI stale metadata and refresh recovery.
