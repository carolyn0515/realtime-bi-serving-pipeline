from pathlib import Path
import sys

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT))

from src.generator.event_stream import event_to_json, stream_events
from src.generator.olist_loader import load_olist_interactions
from src.generator.traffic_profile import (
    load_behavior_delay_profile,
    load_stream_rate_profile,
    load_traffic_profile,
)
from src.generator.ux_event_generator import generate_ux_events


ARCHIVE_DIR = Path("/Users/carolyn/Desktop/study/DataEngineering/project/archive")
TRAFFIC_PROFILE_PATH = Path("configs/local/traffic_profile.yaml")

SAMPLE_SIZE = 100
SEED = 42


def main() -> None:
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

    for event in stream_events(
        events=events,
        stream_rate_profile=stream_rate_profile,
        seed=SEED,
    ):
        print(event_to_json(event), flush=True)


if __name__ == "__main__":
    main()