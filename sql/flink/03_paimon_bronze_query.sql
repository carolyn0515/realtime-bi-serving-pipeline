SET 'execution.runtime-mode' = 'batch';
SET 'sql-client.execution.result-mode' = 'tableau';

CREATE CATALOG paimon WITH (
    'type' = 'paimon',
    'warehouse' = 'file:/warehouse/paimon'
);

USE CATALOG paimon;
USE lakehouse;

SELECT
    event_type,
    COUNT(*) AS event_count,
    MIN(event_ts) AS min_event_ts,
    MAX(event_ts) AS max_event_ts
FROM ux_events_bronze
GROUP BY event_type
ORDER BY event_type;

SELECT
    kafka_partition,
    MIN(kafka_offset) AS min_offset,
    MAX(kafka_offset) AS max_offset,
    COUNT(*) AS row_count
FROM ux_events_bronze
GROUP BY kafka_partition
ORDER BY kafka_partition;
