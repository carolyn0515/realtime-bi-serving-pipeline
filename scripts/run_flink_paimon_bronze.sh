#!/usr/bin/env bash
set -euo pipefail

docker compose \
  -f docker/docker-compose.kafka.yml \
  -f docker/docker-compose.flink.yml \
  up -d flink-jobmanager flink-taskmanager

docker exec realtime-bi-flink-jobmanager \
  chown -R flink:flink /warehouse/paimon

docker compose \
  -f docker/docker-compose.kafka.yml \
  -f docker/docker-compose.flink.yml \
  run --rm flink-sql-client \
  /opt/flink/bin/sql-client.sh \
  -f /opt/flink/usrlib/sql/02_paimon_bronze_ingest.sql

docker compose \
  -f docker/docker-compose.kafka.yml \
  -f docker/docker-compose.flink.yml \
  run --rm flink-sql-client \
  /opt/flink/bin/sql-client.sh \
  -f /opt/flink/usrlib/sql/03_paimon_bronze_query.sql
