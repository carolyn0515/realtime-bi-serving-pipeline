import json
from pathlib import Path
import yaml
from confluent_kafka import Consumer, TopicPartition

KAFKA_CONFIG_PATH = Path("configs/local/kafka.yaml")
MAX_MESSAGES = 20

REQUIRED_FIELDS = {
    "event_id",
    "session_id",
    "user_id",
    "product_id",
    "event_type",
    "event_time",
    "category_code",
    "price",
    "customer_state",
    "seller_state",
    "emitted_at",
}

def validate_event(record: dict) -> None:
    missing = REQUIRED_FIELDS - set(record)
    if missing:
        raise ValueError(f"missing required fields: {sorted(missing)}")

    if record["event_type"] not in {"view", "cart", "purchase"}:
        raise ValueError(f"invalid event_type: {record['event_type']}")

    if record["event_type"] in {"view", "cart"}:
        if record.get("order_id") is not None:
            raise ValueError("view/cart event must not include order_id")
        if record.get("order_item_id") is not None:
            raise ValueError("view/cart event must not include order_item_id")
        if record.get("payment_type") is not None:
            raise ValueError("view/cart event must not include payment_type")
        if record.get("shipping_fee") is not None:
            raise ValueError("view/cart event must not include shipping_fee")

    if record["event_type"] == "purchase":
        if record.get("order_id") is None:
            raise ValueError("purchase event must include order_id")
        if record.get("order_item_id") is None:
            raise ValueError("purchase event must include order_item_id")
        if record.get("payment_type") is None:
            raise ValueError("purchase event must include payment_type")
        if record.get("shipping_fee") is None:
            raise ValueError("purchase event must include shipping_fee")

def main() -> None:
    with KAFKA_CONFIG_PATH.open("r", encoding="utf-8") as f:
        kafka_config = yaml.safe_load(f)
    consumer_config = kafka_config["consumer"]
    topic_config = kafka_config["topic"]
    topic = topic_config["name"]

    consumer = Consumer({
        "bootstrap.servers": kafka_config["bootstrap_servers"],
        "group.id": consumer_config["group_id"],
        "auto.offset.reset": consumer_config["auto_offset_reset"],
        "enable.auto.commit": consumer_config["enable_auto_commit"],
    })

    # Smoke test reads from the beginning independent of committed group offsets.
    partitions = [
        TopicPartition(topic, partition, 0)
        for partition in range(int(topic_config["partitions"]))
    ]
    consumer.assign(partitions)
    consumed_count = 0

    try:
        while consumed_count < MAX_MESSAGES:
            msg = consumer.poll(5.0)
            if msg is None:
                print("no message polled")
                continue
            if msg.error():
                raise RuntimeError(msg.error())
            key = msg.key().decode("utf-8") if msg.key() else None
            value = msg.value().decode("utf-8")
            record = json.loads(value)

            validate_event(record)
            if key != record["session_id"]:
                raise ValueError(
                    f"kafka key must equal session_id: key={key}, session_id={record['session_id']}"
                )

            print(
                f"topic={msg.topic()} "
                f"partition={msg.partition()} "
                f"offset={msg.offset()} "
                f"key={key} "
                f"event_type={record['event_type']} "
                f"session_id={record['session_id']}"
            )

            consumed_count += 1
        
    finally:
        consumer.close()
    
    print(f"consumed_events={consumed_count}")

if __name__ == "__main__":
    main()
