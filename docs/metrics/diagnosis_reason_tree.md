# Diagnosis Reason Tree

## view_to_cart_drop

Users are viewing products but not adding them to cart.

Candidate dimensions:

- `category_code`
- `price_tier`
- `customer_state`
- `seller_state`

Likely interpretations:

- Product attractiveness issue.
- Price sensitivity.
- Regional catalog or fulfillment perception issue.

## cart_to_purchase_drop

Users are adding products to cart but not completing purchase.

Candidate dimensions:

- `customer_state`
- `seller_state`
- `category_code`
- `price_tier`

Likely interpretations:

- Checkout or purchase completion friction.
- Shipping or delivery concern inferred from customer/seller region.
- Regional fulfillment issue.

## view_to_purchase_drop

The whole funnel is down.

Candidate dimensions:

- `category_code`
- `customer_state`
- `seller_state`
- `price_tier`

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
