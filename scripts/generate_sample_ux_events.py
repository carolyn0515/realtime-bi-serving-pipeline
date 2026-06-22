import json
from dataclasses import asdict
from pathlib import Path

from src.generator.olist_loader import load_olist_interactions
from src.generator.traffic_profile import load_behavior_delay_profile, load_traffic_profile
from src.generator.ux_event_generator import generate_ux_events

ARCHIVE_DIR = Path("/Users/carolyn/Desktop/study/DataEngineering/project/archive")
TRAFFIC_PROFILE_PATH = Path("configs/local/traffic_profile.yaml")
OUTPUT_PATH = Path("data/samples/sample_ux_events.jsonl")
SAMPLE_SIZE = 10_000
SEED = 42

def serialize_event(event) -> dict:
    record = asdict(event)
    record["event_time"] = event.event_time.isoformat()
    return record

def main() -> None:
    interactions = load_olist_interactions(ARCHIVE_DIR)
    traffic_profile = load_traffic_profile(TRAFFIC_PROFILE_PATH)
    delay_profile = load_behavior_delay_profile(TRAFFIC_PROFILE_PATH)
    events = generate_ux_events(
        interactions=interactions.head(SAMPLE_SIZE),
        seed=SEED,
        delay_profile=delay_profile,
        traffic_profile=traffic_profile,
    )

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    with OUTPUT_PATH.open("w", encoding="utf-8") as f:
        for event in events:
            record = serialize_event(event)
            f.write(json.dumps(record, ensure_ascii=False) + "\n")
    
    print(f"profile={traffic_profile.name}")
    print(f"interactions={min(len(interactions), SAMPLE_SIZE)}")
    print(f"events={len(events)}")
    print(f"output={OUTPUT_PATH}")

if __name__=="__main__":
    main()