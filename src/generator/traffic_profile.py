from dataclasses import dataclass
from pathlib import Path

import yaml


@dataclass(frozen=True)
class BehaviorDelayProfile:
    view_to_cart_min_seconds: int
    view_to_cart_max_seconds: int
    view_to_purchase_min_seconds: int
    view_to_purchase_max_seconds: int
    cart_to_purchase_min_seconds: int
    cart_to_purchase_max_seconds: int

@dataclass(frozen=True)
class FunnelTrafficProfile:
    name: str
    view_to_cart_probability_min: float
    view_to_cart_probability_max: float
    cart_to_purchase_probability_min: float
    cart_to_purchase_probability_max: float


@dataclass(frozen=True)
class StreamRateProfile:
    mean_events_per_second_min: float
    mean_events_per_second_max: float
    min_sleep_seconds: float
    max_sleep_seconds: float


def validate_ratio(name: str, value: float) -> None:
    if not 0 <= value <= 1:
        raise ValueError(f"{name} must be between 0 and 1")


def validate_range(name: str, min_value: float, max_value: float) -> None:
    if max_value < min_value:
        raise ValueError(f"{name} max must be greater than or equal to min")


def load_traffic_profile(path: str | Path) -> FunnelTrafficProfile:
    path = Path(path)

    with path.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f)

    conversion = raw["conversion_probability"]
    view_to_cart_probability_min = float(conversion["view_to_cart_min"])
    view_to_cart_probability_max = float(conversion["view_to_cart_max"])
    cart_to_purchase_probability_min = float(conversion["cart_to_purchase_min"])
    cart_to_purchase_probability_max = float(conversion["cart_to_purchase_max"])

    validate_ratio("view_to_cart_min", view_to_cart_probability_min)
    validate_ratio("view_to_cart_max", view_to_cart_probability_max)
    validate_ratio("cart_to_purchase_min", cart_to_purchase_probability_min)
    validate_ratio("cart_to_purchase_max", cart_to_purchase_probability_max)
    validate_range("view_to_cart_probability", view_to_cart_probability_min, view_to_cart_probability_max)
    validate_range(
        "cart_to_purchase_probability",
        cart_to_purchase_probability_min,
        cart_to_purchase_probability_max,
    )

    return FunnelTrafficProfile(
        name=raw["name"],
        view_to_cart_probability_min=view_to_cart_probability_min,
        view_to_cart_probability_max=view_to_cart_probability_max,
        cart_to_purchase_probability_min=cart_to_purchase_probability_min,
        cart_to_purchase_probability_max=cart_to_purchase_probability_max,
    )


def load_behavior_delay_profile(path: str | Path) -> BehaviorDelayProfile:
    path = Path(path)

    with path.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f)

    delay = raw["behavior_delay"]

    return BehaviorDelayProfile(
        view_to_cart_min_seconds=int(delay["view_to_cart_min_seconds"]),
        view_to_cart_max_seconds=int(delay["view_to_cart_max_seconds"]),
        view_to_purchase_min_seconds=int(delay["view_to_purchase_min_seconds"]),
        view_to_purchase_max_seconds=int(delay["view_to_purchase_max_seconds"]),
        cart_to_purchase_min_seconds=int(delay["cart_to_purchase_min_seconds"]),
        cart_to_purchase_max_seconds=int(delay["cart_to_purchase_max_seconds"]),
    )


def load_stream_rate_profile(path: str | Path) -> StreamRateProfile:
    path = Path(path)

    with path.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f)

    stream_rate = raw["stream_rate"]

    mean_events_per_second_min = float(stream_rate["mean_events_per_second_min"])
    mean_events_per_second_max = float(stream_rate["mean_events_per_second_max"])
    min_sleep_seconds = float(stream_rate["min_sleep_seconds"])
    max_sleep_seconds = float(stream_rate["max_sleep_seconds"])

    if mean_events_per_second_min <= 0:
        raise ValueError("mean_events_per_second_min must be greater than 0")
    if mean_events_per_second_max <= 0:
        raise ValueError("mean_events_per_second_max must be greater than 0")
    validate_range(
        "mean_events_per_second",
        mean_events_per_second_min,
        mean_events_per_second_max,
    )
    if min_sleep_seconds < 0:
        raise ValueError("min_sleep_seconds must be greater than or equal to 0")
    if max_sleep_seconds < min_sleep_seconds:
        raise ValueError("max_sleep_seconds must be greater than or equal to min_sleep_seconds")

    return StreamRateProfile(
        mean_events_per_second_min=mean_events_per_second_min,
        mean_events_per_second_max=mean_events_per_second_max,
        min_sleep_seconds=min_sleep_seconds,
        max_sleep_seconds=max_sleep_seconds,
    )
