# Realtime Funnel BI Serving Pipeline

실시간 UX 이벤트를 빠르게 처리하되, 품질 검증을 통과한 지표만 BI에 노출하는 신뢰형 Funnel BI Serving Pipeline입니다.

Olist E-Commerce CSV에는 실제 `view`/`cart` 로그가 없으므로, 프로젝트 첫 단계에서 주문/상품/결제/고객/판매자 데이터를 기반으로 synthetic customer behavior log를 생성합니다. 이후 Kafka, Flink, Paimon, StarRocks를 거쳐 dashboard evidence까지 이어지는 end-to-end 흐름을 구성합니다.

## Architecture

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
  -> StarRocks BI serving views
  -> HTML dashboard evidence
```

Core principle:

```text
BI reads serving views backed by DQ-passed published/anomaly marts.
BI does not read Kafka, bronze, clean, or staging tables directly.
```

## What This Project Demonstrates

- Synthetic UX log generation from raw Olist CSV.
- Kafka ingestion with producer/consumer smoke checks.
- Flink SQL event-time ingestion from Kafka.
- Paimon bronze, clean, invalid, staging, published, and anomaly tables.
- DQ publish gate that separates fast staging metrics from BI-readable metrics.
- Session-cohort funnel staging to avoid event-time count distortion.
- Explainable baseline fallback: `exact_segment -> category_price -> global`.
- Sparse-window anomaly suppression to avoid noisy alerts.
- StarRocks external catalog over Paimon.
- Dashboard evidence exported from StarRocks serving views.

## Repository Layout

```text
configs/       Local runtime and service configs
data/          Generated samples and dashboard evidence
docker/        Kafka, Flink, and StarRocks Docker Compose assets
docs/          Architecture, metrics, ADRs, and runbooks
scripts/       Developer and demo helper scripts
sql/           Flink and StarRocks SQL
src/           Generator, ingestion, and serving exporter code
tests/         Focused tests
```

## Prerequisites

- Docker Desktop
- Python 3.11+
- Raw Olist CSV files in:

```text
/Users/carolyn/Desktop/study/DataEngineering/project/archive
```

Install Python dependencies if needed:

```bash
pip install -e .
```

## End-To-End Demo

Run the full local demo:

```bash
./scripts/run_demo_e2e.sh
```

This runs:

```text
Kafka topic creation
-> UX event production
-> Flink Kafka to Paimon bronze
-> Paimon clean/invalid validation
-> Funnel staging
-> DQ publish gate
-> Baseline/anomaly scoring
-> StarRocks serving views
-> Dashboard evidence export
```

Generated dashboard artifacts:

```text
data/generated/starrocks_dashboard/dashboard.html
data/generated/starrocks_dashboard/dashboard_data.json
```

## Step-By-Step Scripts

Kafka:

```bash
docker compose -f docker/docker-compose.kafka.yml up -d
python3 scripts/create_kafka_topic.py
python3 scripts/stream_ux_events_to_kafka.py
python3 scripts/consume_ux_events.py
```

Flink and Paimon:

```bash
./scripts/run_flink_paimon_bronze.sh
./scripts/run_flink_paimon_clean.sh
./scripts/run_flink_paimon_staging.sh
./scripts/run_flink_paimon_publish_gate.sh
./scripts/run_flink_paimon_anomaly.sh
```

StarRocks and dashboard evidence:

```bash
./scripts/run_starrocks_paimon_serving.sh
./scripts/export_starrocks_dashboard.sh
```

## Key Tables

Paimon:

```text
lakehouse.ux_events_bronze
lakehouse.ux_events_clean
lakehouse.ux_events_invalid
lakehouse.session_funnel_staging
lakehouse.mart_funnel_1h_staging
lakehouse.dq_audit_result
lakehouse.mart_funnel_1h_published
lakehouse.funnel_baseline_profile
lakehouse.mart_funnel_1h_anomaly
```

StarRocks:

```text
paimon_lakehouse.lakehouse.mart_funnel_1h_anomaly
bi_serving.v_funnel_health
bi_serving.v_anomaly_watchlist
```

## Design Notes

### Raw Stream Boundary

The raw UX stream is shaped like customer behavior logs. It does not include BI-only fields such as tiered diagnosis labels.

### Staging Grain

The hourly funnel mart is built from session state and attributed to the view-start hour. This avoids a common distortion where a view occurs in one hour and cart/purchase occur in later hours, causing per-window conversion rates to exceed `1`.

### Publish Gate

Staging rows are audited before publication. Failed rows remain visible in `dq_audit_result`, but only `PASS` rows enter `mart_funnel_1h_published`.

### Anomaly Scoring

Baseline comparison uses a fallback hierarchy:

```text
exact_segment -> category_price -> global
```

Small current windows are scored but not promoted to warning or critical anomalies. This prevents overconfident alerts from sparse samples.

### StarRocks Serving

StarRocks queries Paimon through an external catalog. In local development, the Paimon warehouse Docker volume is mounted read-only into StarRocks.

## Current Evidence

The latest smoke run produced:

```text
served_rows: 98
total_views: 200
total_carts: 75
total_purchases: 32
overall_view_to_cart_rate: 37.5%
overall_cart_to_purchase_rate: 42.7%
overall_view_to_purchase_rate: 16.0%
watchlist_rows: 0
```

`watchlist_rows=0` is expected for the current sample because anomaly alerts require enough current volume before being promoted to warning or critical.
