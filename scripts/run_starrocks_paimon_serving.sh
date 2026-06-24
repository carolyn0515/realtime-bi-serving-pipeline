#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILES=(
  -f docker/docker-compose.starrocks.yml
)

MYSQL_CMD=(mysql -h127.0.0.1 -P9030 -uroot --batch --raw)

docker compose "${COMPOSE_FILES[@]}" up -d starrocks

for _ in $(seq 1 60); do
  if docker exec realtime-bi-starrocks "${MYSQL_CMD[@]}" -e "SELECT 1;" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

docker exec realtime-bi-starrocks "${MYSQL_CMD[@]}" -e "SELECT 1;" >/dev/null

for _ in $(seq 1 60); do
  if docker exec realtime-bi-starrocks "${MYSQL_CMD[@]}" -e "SHOW PROC '/backends';" \
    | grep -q $'\ttrue\t'; then
    break
  fi
  sleep 2
done

docker exec realtime-bi-starrocks "${MYSQL_CMD[@]}" -e "SHOW PROC '/backends';" \
  | grep -q $'\ttrue\t'

docker exec -i realtime-bi-starrocks "${MYSQL_CMD[@]}" \
  < sql/starrocks/01_create_paimon_catalog.sql

docker exec -i realtime-bi-starrocks "${MYSQL_CMD[@]}" \
  < sql/starrocks/02_create_serving_views.sql

docker exec -i realtime-bi-starrocks "${MYSQL_CMD[@]}" \
  < sql/starrocks/03_query_serving_views.sql
