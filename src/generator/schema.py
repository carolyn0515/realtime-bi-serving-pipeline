from dataclasses import dataclass
from datetime import datetime

@dataclass(frozen=True)
class UxEvent:
    event_id: str
    session_id: str
    user_id: str
    order_id: str | None
    order_item_id: str | None
    product_id: str
    event_type: str
    event_time: datetime
    category_code: str
    price: float
    price_tier: str
    review_score: float | None
    review_tier: str
    freight_value: float
    freight_tier: str
    payment_type: str
    customer_state: str
    seller_state: str
    is_anomaly: bool = False
    anomaly_type: str | None = None