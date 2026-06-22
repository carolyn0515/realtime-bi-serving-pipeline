from datetime import timedelta
from uuid import uuid4
import pandas as pd
import numpy as np
from src.generator.features import freight_tier, price_tier, review_tier
from src.generator.schema import UxEvent
from src.generator.traffic_profile import BehaviorDelayProfile

def sample_event_times(
        purchase_time: pd.Timestamp,
        rng: np.random.Generator,
        delay_profile: BehaviorDelayProfile,
) -> tuple[pd.Timestamp, pd.Timestamp, pd.Timestamp]:
    
    view_to_purchase_seconds = rng.integers(
        delay_profile.view_to_purchase_min_seconds,
        delay_profile.view_to_purchase_max_seconds + 1,
    )

    cart_to_purchase_upper_bound = min(
        delay_profile.cart_to_purchase_max_seconds,
        view_to_purchase_seconds-1,
    )

    cart_to_purchase_seconds = rng.integers(
        delay_profile.cart_to_purchase_min_seconds,
        cart_to_purchase_upper_bound + 1,
    )

    view_time = purchase_time - timedelta(seconds=int(view_to_purchase_seconds))
    cart_time = purchase_time - timedelta(seconds=int(cart_to_purchase_seconds))

    return view_time, cart_time, purchase_time


def generate_ux_events(
    interactions: pd.DataFrame,
    seed: int=42,
    delay_profile: BehaviorDelayProfile | None = None,
) -> list[UxEvent]:
    delay_profile = delay_profile or BehaviorDelayProfile()
    rng = np.random.default_rng(seed)
    shuffled_indices = rng.permutation(len(interactions))

    events: list[UxEvent] = []

    for idx in shuffled_indices:
        row = interactions.iloc[idx]
        session_id = str(uuid4())
        user_id = row["customer_unique_id"]
        order_id = row["order_id"]
        order_item_id = f"{row['order_id']}:{row['order_item_id']}"
        product_id = row["product_id"]

        purchase_time = row["order_purchase_timestamp"]
        view_time, cart_time, purchase_time = sample_event_times(
            purchase_time=purchase_time,
            rng=rng,
            delay_profile=delay_profile,
        )

        review_score = None if pd.isna(row.get("review_score")) else float(row["review_score"])

        base = {
            "session_id": session_id,
            "user_id": user_id,
            "order_id": order_id,
            "order_item_id": order_item_id,
            "product_id": product_id,
            "category_code": row.get("product_category_name") or "unknown",
            "price": float(row["price"]),
            "price_tier": price_tier(float(row["price"])),
            "review_score": review_score,
            "review_tier": review_tier(review_score),
            "freight_value": float(row["freight_value"]),
            "freight_tier": freight_tier(float(row["freight_value"])),
            "payment_type": row.get("payment_type") or "unknown",
            "customer_state": row.get("customer_state") or "unknown",
            "seller_state": row.get("seller_state") or "unknown",
        }

        events.append(
            UxEvent(
                event_id=str(uuid4()),
                event_type="view",
                event_time=view_time,
                **base
            )
        )

        events.append(
            UxEvent(
                event_id=str(uuid4()),
                event_type="cart",
                event_time=cart_time,
                **base,
            )
        )

        events.append(
            UxEvent(
                event_id=str(uuid4()),
                event_type="purchase",
                event_time=purchase_time,
                **base,
            )
        )

    events.sort(key=lambda event: event.event_time)
    return events