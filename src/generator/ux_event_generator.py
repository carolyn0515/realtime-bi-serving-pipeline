from datetime import timedelta
from uuid import uuid4

import numpy as np
import pandas as pd

from src.generator.schema import UxEvent
from src.generator.traffic_profile import BehaviorDelayProfile, FunnelTrafficProfile


def sample_probability(
    rng: np.random.Generator,
    min_value: float,
    max_value: float,
) -> float:
    return float(rng.uniform(min_value, max_value))


def sample_funnel_outcome(
    rng: np.random.Generator,
    traffic_profile: FunnelTrafficProfile,
) -> str:
    view_to_cart_probability = sample_probability(
        rng,
        traffic_profile.view_to_cart_probability_min,
        traffic_profile.view_to_cart_probability_max,
    )
    has_cart = rng.random() < view_to_cart_probability
    if not has_cart:
        return "view_only"

    cart_to_purchase_probability = sample_probability(
        rng,
        traffic_profile.cart_to_purchase_probability_min,
        traffic_profile.cart_to_purchase_probability_max,
    )
    has_purchase = rng.random() < cart_to_purchase_probability
    if not has_purchase:
        return "cart_abandoned"
    return "purchased"


def sample_event_times_for_outcome(
    anchor_time: pd.Timestamp,
    outcome: str,
    rng: np.random.Generator,
    delay_profile: BehaviorDelayProfile,
) -> dict[str, pd.Timestamp]:
    if outcome == "view_only":
        return {
            "view": anchor_time,
        }

    if outcome == "cart_abandoned":
        view_to_cart_seconds = rng.integers(
            delay_profile.view_to_cart_min_seconds,
            delay_profile.view_to_cart_max_seconds + 1,
        )

        view_time = anchor_time - timedelta(seconds=int(view_to_cart_seconds))
        cart_time = anchor_time

        return {
            "view": view_time,
            "cart": cart_time,
        }

    if outcome == "purchased":
        view_to_purchase_seconds = rng.integers(
            delay_profile.view_to_purchase_min_seconds,
            delay_profile.view_to_purchase_max_seconds + 1,
        )

        cart_to_purchase_upper_bound = min(
            delay_profile.cart_to_purchase_max_seconds,
            view_to_purchase_seconds - 1,
        )

        cart_to_purchase_seconds = rng.integers(
            delay_profile.cart_to_purchase_min_seconds,
            cart_to_purchase_upper_bound + 1,
        )

        view_time = anchor_time - timedelta(seconds=int(view_to_purchase_seconds))
        cart_time = anchor_time - timedelta(seconds=int(cart_to_purchase_seconds))
        purchase_time = anchor_time

        return {
            "view": view_time,
            "cart": cart_time,
            "purchase": purchase_time,
        }

    raise ValueError(f"Unsupported funnel outcome: {outcome}")


def generate_ux_events(
    interactions: pd.DataFrame,
    seed: int | None,
    delay_profile: BehaviorDelayProfile,
    traffic_profile: FunnelTrafficProfile,
) -> list[UxEvent]:
    rng = np.random.default_rng(seed)
    shuffled_indices = rng.permutation(len(interactions))

    events: list[UxEvent] = []

    for idx in shuffled_indices:
        row = interactions.iloc[idx]

        outcome = sample_funnel_outcome(
            rng=rng,
            traffic_profile=traffic_profile,
        )

        event_times = sample_event_times_for_outcome(
            anchor_time=row["order_purchase_timestamp"],
            outcome=outcome,
            rng=rng,
            delay_profile=delay_profile,
        )

        session_id = str(uuid4())
        user_id = row["customer_unique_id"]
        product_id = row["product_id"]

        common_base = {
            "session_id": session_id,
            "user_id": user_id,
            "product_id": product_id,
            "category_code": row.get("product_category_name") or "unknown",
            "price": float(row["price"]),
            "customer_state": row.get("customer_state") or "unknown",
            "seller_state": row.get("seller_state") or "unknown",
        }

        for event_type in ("view", "cart", "purchase"):
            if event_type not in event_times:
                continue

            order_id = None
            order_item_id = None
            payment_type = None
            shipping_fee = None

            if event_type == "purchase":
                order_id = row["order_id"]
                order_item_id = f"{row['order_id']}:{row['order_item_id']}"
                payment_type = row.get("payment_type") or "unknown"
                shipping_fee = float(row["freight_value"])

            events.append(
                UxEvent(
                    event_id=str(uuid4()),
                    event_type=event_type,
                    event_time=event_times[event_type],
                    order_id=order_id,
                    order_item_id=order_item_id,
                    payment_type=payment_type,
                    shipping_fee=shipping_fee,
                    **common_base,
                )
            )

    events.sort(key=lambda event: event.event_time)
    return events
