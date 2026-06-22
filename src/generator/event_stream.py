from collections.abc import Iterator
from dataclasses import asdict
from datetime import datetime, timezone
import json
import time

import numpy as np

from src.generator.schema import UxEvent
from src.generator.traffic_profile import StreamRateProfile


def event_to_record(event: UxEvent) -> dict:
    record = asdict(event)
    record["event_time"] = event.event_time.isoformat()
    record["emitted_at"] = datetime.now(timezone.utc).isoformat()
    return record


def event_to_json(event: UxEvent) -> str:
    return json.dumps(event_to_record(event), ensure_ascii=False)


def sample_sleep_seconds(
    rng: np.random.Generator,
    stream_rate_profile: StreamRateProfile,
) -> float:
    mean_interval_seconds = 1 / stream_rate_profile.mean_events_per_second
    sleep_seconds = rng.exponential(mean_interval_seconds)

    return float(
        np.clip(
            sleep_seconds,
            stream_rate_profile.min_sleep_seconds,
            stream_rate_profile.max_sleep_seconds,
        )
    )


def stream_events(
    events: list[UxEvent],
    stream_rate_profile: StreamRateProfile,
    seed: int,
) -> Iterator[UxEvent]:
    rng = np.random.default_rng(seed)

    for event in events:
        yield event
        time.sleep(sample_sleep_seconds(rng, stream_rate_profile))