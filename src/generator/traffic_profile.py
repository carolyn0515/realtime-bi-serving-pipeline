from dataclasses import dataclass

@dataclass(frozen=True)
class BehaviorDelayProfile:
    view_to_purchase_min_seconds: int=60
    view_to_purchase_max_seconds: int=30*60
    cart_to_purchase_min_seconds: int=30
    cart_to_purchase_max_seconds: int=10*60