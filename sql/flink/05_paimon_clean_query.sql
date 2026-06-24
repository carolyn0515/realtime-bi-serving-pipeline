SET 'execution.runtime-mode' = 'batch';
SET 'sql-client.execution.result-mode' = 'tableau';

CREATE CATALOG paimon WITH (
    'type' = 'paimon',
    'warehouse' = 'file:/warehouse/paimon'
);

USE CATALOG paimon;
USE lakehouse;

SELECT
    'bronze' AS layer,
    COUNT(*) AS row_count
FROM ux_events_bronze
UNION ALL
SELECT
    'clean' AS layer,
    COUNT(*) AS row_count
FROM ux_events_clean
UNION ALL
SELECT
    'invalid' AS layer,
    COUNT(*) AS row_count
FROM ux_events_invalid;

SELECT
    event_type,
    COUNT(*) AS event_count,
    COUNT(DISTINCT session_id) AS session_count,
    MIN(event_ts) AS min_event_ts,
    MAX(event_ts) AS max_event_ts
FROM ux_events_clean
GROUP BY event_type
ORDER BY event_type;

SELECT
    validation_error,
    COUNT(*) AS rejected_count
FROM ux_events_invalid
GROUP BY validation_error
ORDER BY rejected_count DESC, validation_error;
