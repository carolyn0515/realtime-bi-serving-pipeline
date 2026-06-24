# Paimon Bronze Design

## Role

The Bronze layer is the first durable lakehouse boundary after Kafka.

```text
Kafka ux-events
  -> Flink Kafka source
  -> Paimon ux_events_bronze
```

Bronze is not a BI mart. It preserves raw customer behavior events together with Kafka operational metadata so the pipeline can be replayed, audited, and debugged later.

## Why Append Table

`ux_events_bronze` has no primary key, so Paimon treats it as an append table.

This matches the raw UX event model:

- each customer behavior event is immutable
- view/cart/purchase events are appended
- no upsert is required at Bronze
- event corrections should arrive as additional records or later clean-layer handling

## Catalog

Local development uses a filesystem Paimon catalog:

```sql
CREATE CATALOG paimon WITH (
    'type' = 'paimon',
    'warehouse' = 'file:/warehouse/paimon'
);
```

The warehouse is mounted as a Docker volume and shared by Flink JobManager, TaskManager, and SQL Client.

The Flink image includes:

- Flink Kafka SQL connector
- Flink JSON format connector
- Flink shaded Hadoop jar
- Paimon Flink 1.19 bundled jar

The Hadoop shaded jar is required because the Paimon filesystem catalog loads Hadoop filesystem configuration classes even when the local warehouse path is `file:/...`.

## Table Grain

One row equals one raw UX event.

Key fields:

- `event_id`
- `session_id`
- `user_id`
- `product_id`
- `event_type`
- `event_time`
- `event_ts`

Purchase-only fields:

- `order_id`
- `order_item_id`
- `payment_type`
- `shipping_fee`

Operational fields:

- `emitted_at`
- `kafka_partition`
- `kafka_offset`
- `kafka_timestamp`

Partition:

- `dt = DATE_FORMAT(event_ts, 'yyyy-MM-dd')`

## Ingestion Mode

The first smoke ingestion uses a bounded Kafka source:

```sql
'scan.startup.mode' = 'earliest-offset'
'scan.bounded.mode' = 'latest-offset'
```

This lets the SQL job ingest the currently available Kafka records into Bronze and then finish, which makes local verification repeatable.

The production-style streaming job will remove the bounded option and run continuously.

## Completion Criteria

This stage is complete when:

- Paimon connector is available in the Flink image.
- Flink creates a Paimon catalog.
- `ux_events_bronze` is created as an append table.
- Kafka records are inserted into Bronze.
- Batch query over Bronze returns event counts and Kafka offset ranges.

## Next Step

After Bronze works, add a clean/validation path:

```text
ux_events_bronze
  -> valid clean events
  -> invalid/malformed event table
```
