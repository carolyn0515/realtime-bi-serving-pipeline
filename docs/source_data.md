# Source Data

Raw source files are stored outside this repository:

```text
/Users/carolyn/Desktop/study/DataEngineering/project/archive
```

Expected Kaggle Olist files:

- `olist_customers_dataset.csv`
- `olist_geolocation_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_order_payments_dataset.csv`
- `olist_order_reviews_dataset.csv`
- `olist_orders_dataset.csv`
- `olist_products_dataset.csv`
- `olist_sellers_dataset.csv`
- `product_category_name_translation.csv`

## First Transformation Goal

The first implementation task is to convert these order-centric CSV files into synthetic UX events:

```text
view -> cart -> purchase
```

The generated events become the canonical input for Kafka and downstream streaming jobs.
