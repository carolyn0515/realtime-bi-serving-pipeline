# Flink Design

## Role

Flink is the first processing boundary after Kafka.

For this stage, Flink does not build BI marts. It only proves that the raw UX event stream can be read as an event-time table and prepared for Bronze append-log ingestion.

```text
Kafka ux-events
  -> Flink Kafka SQL source
  -> JSON decoding
  -> event-time column
  -> watermark
  -> smoke query
```

## Version Decision

The local smoke test uses Flink `1.19.3`.

The Flink 2.1 Kafka SQL connector page currently says no connector is available for that version. Flink 1.19 documents the Kafka SQL connector dependency as `flink-connector-kafka` version `3.3.0-1.19`, so the local Docker image installs the matching SQL connector jar.

## Kafka Source Table

The source table reads `ux-events` from Kafka.

Important options:

- `connector = kafka`
- `topic = ux-events`
- `properties.bootstrap.servers = kafka:9092`
- `properties.group.id = flink-ux-events-smoke`
- `scan.startup.mode = earliest-offset`
- `format = json`

## Time Semantics

The raw event contains two time fields:

- `event_time`: customer behavior time from the simulated event
- `emitted_at`: generator emission time

Flink uses `event_time` for event-time semantics because BI time-series views must reflect when the customer behavior happened, not when the replay generator emitted the record.

The SQL source creates:

```sql
event_ts AS TO_TIMESTAMP(event_time)
WATERMARK FOR event_ts AS event_ts - INTERVAL '30' SECOND
```

This leaves room for out-of-order records while keeping the stream usable for windowed processing later.

## Kafka Metadata

The smoke table exposes Kafka metadata columns:

- `partition`
- `offset`
- `timestamp`

These fields are not BI dimensions. They are operational evidence for replay, debugging, and Bronze ingestion verification.

## Completion Criteria

This stage is complete when:

- Flink JobManager and TaskManager run locally.
- Flink SQL Client can create the Kafka source table.
- The smoke query reads records from `ux-events`.
- Kafka partition and offset are visible.
- `event_time` is parsed into `event_ts`.
- `view` and `cart` rows show null purchase-completion fields.
- `purchase` rows contain order/payment/shipping fields.

## Next Stage

After the smoke query works, the next step is Bronze ingestion:

```text
ux_events_raw
  -> valid raw event append sink
  -> invalid event side path
```

The sink will initially be filesystem or print for debug, then Paimon Bronze once connector dependencies are stable.
