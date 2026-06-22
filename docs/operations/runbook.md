# Operations Runbook

## Recovery Scenarios

- Flink failure: restart from the latest successful checkpoint.
- Flink upgrade: stop with savepoint, deploy new job, resume from savepoint.
- Kafka replay: reset consumer offsets and recompute downstream tables.
- Staging mart error: recompute affected windows from clean events.
- Published mart contamination: rollback to the last known-good published snapshot.
- Baseline error: rollback Iceberg to a recorded snapshot ID.
- StarRocks stale metadata: run external table refresh.

## Evidence To Capture

- Kafka consumer lag.
- Flink checkpoint status.
- Paimon snapshot progression.
- DQ PASS or FAIL history.
- StarRocks refresh timestamp.
- Dashboard last updated timestamp.
- OpenMetadata lineage screenshot.
