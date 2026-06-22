def price_tier(price: float) -> str:
    if price < 50:
        return "low"
    if price < 150:
        return "mid"
    return "high"


def freight_tier(freight_value: float) -> str:
    if freight_value < 10:
        return "low"
    if freight_value < 30:
        return "mid"
    return "high"


def review_tier(review_score: float | None) -> str:
    if review_score is None:
        return "unknown"
    if review_score <= 2:
        return "low"
    if review_score <= 4:
        return "mid"
    return "high"