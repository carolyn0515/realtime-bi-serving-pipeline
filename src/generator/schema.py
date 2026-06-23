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
    payment_type: str | None
    shipping_fee: float | None
    customer_state: str
    seller_state: str
