# Operations Runbook

## Recovery Scenarios

- Flink failure: restart from the latest successful checkpoint.
- Flink upgrade: stop with savepoint, deploy new job, resume from savepoint.
- Kafka replay: reset consumer offsets and recompute downstream tables.
- Staging mart error: recompute affected windows from clean events.
- Published mart contamination: rollback to the last known-good published snapshot.
- Baseline error: rebuild `funnel_baseline_profile` and `mart_funnel_1h_anomaly` from `mart_funnel_1h_published`.
- StarRocks stale metadata: recreate the Paimon external catalog and serving views.

## Local Demo Recovery

If a local smoke run becomes inconsistent, rerun the layers from the last trusted boundary:

```bash
./scripts/run_flink_paimon_bronze.sh
./scripts/run_flink_paimon_clean.sh
./scripts/run_flink_paimon_staging.sh
./scripts/run_flink_paimon_publish_gate.sh
./scripts/run_flink_paimon_anomaly.sh
./scripts/run_starrocks_paimon_serving.sh
./scripts/export_starrocks_dashboard.sh
```

To rerun everything from the beginning:

```bash
./scripts/run_demo_e2e.sh
```

## Evidence To Capture

- Kafka consumer lag.
- Flink checkpoint status.
- Paimon snapshot progression.
- DQ PASS or FAIL history.
- StarRocks refresh timestamp.
- Dashboard last updated timestamp.
- Dashboard evidence files:
  - `data/generated/starrocks_dashboard/dashboard.html`
  - `data/generated/starrocks_dashboard/dashboard_data.json`

## Smoke Checks

Kafka:

```bash
python3 scripts/consume_ux_events.py
```

Paimon anomaly mart:

```bash
./scripts/run_flink_paimon_anomaly.sh
```

StarRocks serving:

```bash
./scripts/run_starrocks_paimon_serving.sh
```

Dashboard export:

```bash
./scripts/export_starrocks_dashboard.sh
```
