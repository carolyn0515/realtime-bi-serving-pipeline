# Realtime Funnel BI Serving Pipeline

실시간 UX 이벤트를 빠르게 집계하되, 품질 검증을 통과한 window만 BI에 publish하는 신뢰형 Funnel Mart Serving Pipeline입니다.

원본 데이터는 `/Users/carolyn/Desktop/study/DataEngineering/project/archive`의 Olist E-Commerce CSV를 사용합니다. Olist에는 실제 `view`/`cart` 로그가 없으므로, 첫 단계에서는 주문/상품/결제/리뷰 데이터를 기반으로 synthetic UX log를 생성합니다.

## Project Flow

```text
Olist CSV
  -> UX Log Generator
  -> Kafka ux-events
  -> Flink streaming jobs
  -> Paimon bronze / clean / staging
  -> DQ Audit + Publish Gate
  -> Paimon published mart
  -> Spark baseline batch
  -> Iceberg funnel baseline
  -> StarRocks external catalog
  -> BI dashboard
  -> OpenMetadata lineage
```

## Repository Layout

```text
configs/       Local runtime and service configs
data/          Generated samples and local outputs
docker/        Local full-stack Docker Compose assets
docs/          Architecture, metrics, ADRs, and runbooks
notebooks/     Exploratory checks for the Olist source data
scripts/       Developer and demo helper scripts
sql/           Paimon, Iceberg, and StarRocks DDL/views
src/           Pipeline source code
tests/         Focused tests for generator, experiments, and DQ logic
```

## First Milestone

The first milestone is to convert raw Olist CSV files into the UX event shape required by this project:

```text
view -> cart -> purchase
```

The generator must support normal traffic, anomaly injection, late events, malformed events, and repeatable seeds so window-size experiments can be reproduced.
