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
    view_to_cart_ratio: float
    cart_to_purchase_ratio: float

def validate_ratio(name: str, value: float) -> None:
    if not 0 <= value <= 1:
        raise ValueError(f"{name} must be between 0 and 1")

def load_traffic_profile(path: str | Path) -> FunnelTrafficProfile:
    path = Path(path)

    with path.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f)

    view_to_cart_ratio = float(raw["view_to_cart_ratio"])
    cart_to_purchase_ratio = float(raw["cart_to_purchase_ratio"])

    validate_ratio("view_to_cart_ratio", view_to_cart_ratio)
    validate_ratio("cart_to_purchase_ratio", cart_to_purchase_ratio)

    return FunnelTrafficProfile(
        name=raw["name"],
        view_to_cart_ratio=view_to_cart_ratio,
        cart_to_purchase_ratio=cart_to_purchase_ratio,
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