# Kafka Design

## Role

Kafka is the transport and replay boundary for raw UX customer behavior events.

It is not a BI mart. It stores append-only raw events that will later feed the Flink Bronze layer.

## Topic

- Topic: `ux-events`
- Cleanup policy: `delete`
- Retention: 7 days locally
- Partitions: 3 for local development
- Replication factor: 1 for local development

## Message Key

The Kafka message key is `session_id`.

Reason:

- Events within the same session should stay in the same partition.
- Session-level order matters for `view -> cart -> purchase`.
- Global ordering across the full topic is not required.

## Message Value

The value is raw UX event JSON.

Raw stream fields should represent what can be observed at customer behavior time.

`view` and `cart` events must not contain order/payment/shipping completion fields.

`purchase` events may contain:

- `order_id`
- `order_item_id`
- `payment_type`
- `shipping_fee`

## Producer Reliability

The producer favors raw-log durability over minimum latency.

Local producer settings:

- `acks=all`
- `enable.idempotence=true`
- `compression.type=lz4`
- `linger.ms=5`

## Consumer Smoke Test

The smoke-test consumer reads from `earliest` and validates:

- required fields
- valid event type
- key equals session-level routing intent
- no future leakage in `view` and `cart`
- purchase completion fields exist only on `purchase`

## Next Layer

Flink will consume `ux-events` and write the raw append log to the Bronze table.
Kafka retention remains the replay buffer before Bronze ingestion is trusted.