from pathlib import Path
import pandas as pd
import yaml
from src.generator.traffic_profile import StreamRateProfile

def load_olist_interactions(archive_dir: str | Path) -> pd.DataFrame:
    archive_dir = Path(archive_dir)
    orders = pd.read_csv(archive_dir / "olist_orders_dataset.csv")
    items = pd.read_csv(archive_dir / "olist_order_items_dataset.csv")
    products = pd.read_csv(archive_dir / "olist_products_dataset.csv")
    payments = pd.read_csv(archive_dir / "olist_order_payments_dataset.csv")
    reviews = pd.read_csv(archive_dir / "olist_order_reviews_dataset.csv")
    customers = pd.read_csv(archive_dir / "olist_customers_dataset.csv")
    sellers = pd.read_csv(archive_dir / "olist_sellers_dataset.csv")

    df = items.merge(orders, on="order_id", how="inner")
    df = df.merge(products, on="product_id", how="left")
    df = df.merge(payments, on="order_id", how="left")
    df = df.merge(reviews, on="order_id", how="left")
    df = df.merge(customers, on="customer_id", how="left")
    df = df.merge(sellers, on="seller_id", how="left")

    df = df[df["order_status"] == "delivered"].copy()

    df["order_purchase_timestamp"] = pd.to_datetime(df["order_purchase_timestamp"])
    df["review_score"] = df["review_score"].astype("float")

    return df

def laod_stream_rate_profile(path: str | Path) -> StreamRateProfile:
    path = Path(path)
    with path.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f)
    stream_rate = raw["stream_rate"]

    return StreamRateProfile(
        mean_events_per_second=float(stream_rate["mean_events_per_second"]),
        min_sleep_seconds=float(stream_rate["min_sleep_seconds"]),
        max_sleep_seconds=float(stream_rate["max_sleep_seconds"]),
    )