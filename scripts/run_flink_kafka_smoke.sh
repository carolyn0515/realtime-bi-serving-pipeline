#!/usr/bin/env bash
set -euo pipefail

docker compose \
  -f docker/docker-compose.kafka.yml \
  -f docker/docker-compose.flink.yml \
  up -d flink-jobmanager flink-taskmanager

docker compose \
  -f docker/docker-compose.kafka.yml \
  -f docker/docker-compose.flink.yml \
  run --rm flink-sql-client \
  /opt/flink/bin/sql-client.sh \
  -f /opt/flink/usrlib/sql/01_kafka_source_smoke.sql
