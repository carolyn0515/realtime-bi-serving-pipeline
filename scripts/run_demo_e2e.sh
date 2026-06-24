#!/usr/bin/env bash
set -euo pipefail

echo "[1/9] Start Kafka"
docker compose -f docker/docker-compose.kafka.yml up -d

echo "[2/9] Create Kafka topic"
python3 scripts/create_kafka_topic.py

echo "[3/9] Produce synthetic UX events"
python3 scripts/stream_ux_events_to_kafka.py

echo "[4/9] Ingest Kafka events into Paimon bronze"
./scripts/run_flink_paimon_bronze.sh

echo "[5/9] Validate bronze into clean and invalid tables"
./scripts/run_flink_paimon_clean.sh

echo "[6/9] Build funnel staging marts"
./scripts/run_flink_paimon_staging.sh

echo "[7/9] Run DQ publish gate"
./scripts/run_flink_paimon_publish_gate.sh

echo "[8/9] Score baseline and anomalies"
./scripts/run_flink_paimon_anomaly.sh

echo "[9/9] Create StarRocks serving views and export dashboard evidence"
./scripts/run_starrocks_paimon_serving.sh
./scripts/export_starrocks_dashboard.sh

cat <<'MSG'

Demo complete.

Dashboard evidence:
  data/generated/starrocks_dashboard/dashboard.html
  data/generated/starrocks_dashboard/dashboard_data.json

StarRocks:
  mysql -h127.0.0.1 -P9030 -uroot

Primary BI view:
  bi_serving.v_funnel_health
MSG
