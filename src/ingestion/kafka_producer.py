import json
from dataclasses import asdict
from datetime import datetime, timezone
from typing import Any

from confluent_kafka import Producer

from src.generator.schema import UxEvent


def event_to_kafka_record(event: UxEvent) -> dict[str, Any]:
    record = asdict(event)
    record["event_time"] = event.event_time.isoformat()
    record["emitted_at"] = datetime.now(timezone.utc).isoformat()
    return record


def event_key(event: UxEvent) -> str:
    return event.session_id


def event_value(event: UxEvent) -> str:
    return json.dumps(event_to_kafka_record(event), ensure_ascii=False)


def build_producer(kafka_config: dict) -> Producer:
    producer_config = kafka_config["producer"]

    return Producer(
        {
            "bootstrap.servers": kafka_config["bootstrap_servers"],
            "client.id": producer_config["client_id"],
            "acks": producer_config["acks"],
            "enable.idempotence": producer_config["enable_idempotence"],
            "compression.type": producer_config["compression_type"],
            "linger.ms": producer_config["linger_ms"],
        }
    )


def delivery_report(err, msg) -> None:
    if err is not None:
        print(f"delivery failed: {err}")
        return

    key = msg.key().decode("utf-8") if msg.key() else None
    print(
        "delivered "
        f"topic={msg.topic()} "
        f"partition={msg.partition()} "
        f"offset={msg.offset()} "
        f"key={key}"
    )


def send_event(producer: Producer, topic: str, event: UxEvent) -> None:
    producer.produce(
        topic=topic,
        key=event_key(event).encode("utf-8"),
        value=event_value(event).encode("utf-8"),
        on_delivery=delivery_report,
    )
    producer.poll(0)