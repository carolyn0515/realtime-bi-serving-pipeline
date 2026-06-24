import sys
from pathlib import Path

import yaml

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT))

from src.generator.event_stream import stream_events
from src.generator.olist_loader import load_olist_interactions
from src.generator.traffic_profile import (
    load_behavior_delay_profile,
    load_stream_rate_profile,
    load_traffic_profile,
)
from src.generator.ux_event_generator import generate_ux_events
from src.ingestion.kafka_producer import build_producer, send_event


ARCHIVE_DIR = Path("/Users/carolyn/Desktop/study/DataEngineering/project/archive")
TRAFFIC_PROFILE_PATH = Path("configs/local/traffic_profile.yaml")
KAFKA_CONFIG_PATH = Path("configs/local/kafka.yaml")

SAMPLE_SIZE = 100
SEED = None


def main() -> None:
    with KAFKA_CONFIG_PATH.open("r", encoding="utf-8") as f:
        kafka_config = yaml.safe_load(f)

    interactions = load_olist_interactions(ARCHIVE_DIR).head(SAMPLE_SIZE)

    traffic_profile = load_traffic_profile(TRAFFIC_PROFILE_PATH)
    delay_profile = load_behavior_delay_profile(TRAFFIC_PROFILE_PATH)
    stream_rate_profile = load_stream_rate_profile(TRAFFIC_PROFILE_PATH)

    events = generate_ux_events(
        interactions=interactions,
        seed=SEED,
        delay_profile=delay_profile,
        traffic_profile=traffic_profile,
    )

    producer = build_producer(kafka_config)
    topic = kafka_config["topic"]["name"]

    sent_count = 0

    for event in stream_events(
        events=events,
        stream_rate_profile=stream_rate_profile,
        seed=SEED,
    ):
        send_event(producer, topic, event)
        sent_count += 1

    producer.flush()

    print(f"sent_events={sent_count}")
    print(f"topic={topic}")


if __name__ == "__main__":
    main()