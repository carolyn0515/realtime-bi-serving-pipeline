# Diagnosis Reason Tree

## view_to_cart_drop

Users are viewing products but not adding them to cart.

Candidate dimensions:

- `category_code`
- `price_tier`
- `review_tier`
- `freight_tier`

Likely interpretations:

- Product attractiveness issue.
- Price sensitivity.
- Review quality issue.
- Shipping cost concern before cart.

## cart_to_purchase_drop

Users are adding products to cart but not completing purchase.

Candidate dimensions:

- `payment_type`
- `freight_tier`
- `customer_state`
- `seller_state`

Likely interpretations:

- Payment friction.
- Shipping cost or delivery concern.
- Regional fulfillment issue.

## view_to_purchase_drop

The whole funnel is down.

Candidate dimensions:

- `category_code`
- `customer_state`
- `seller_state`
- `payment_type`

Likely interpretations:

- Broad service issue.
- Data quality issue.
- Category-wide demand change.

## data_quality_issue

The pipeline cannot produce trustworthy numbers for the current window.

Candidate indicators:

- Freshness lag exceeded.
- Late event ratio exceeded.
- Missing dimensions.
- Invalid count relationship.
- Kafka or Flink lag.
