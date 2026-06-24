import sys
from pathlib import Path
import yaml
from confluent_kafka.admin import AdminClient, NewTopic
PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT))
CONFIG_PATH = Path("configs/local/kafka.yaml")

def main() -> None:
    with CONFIG_PATH.open("r", encoding="utf-8") as f:
        config = yaml.safe_load(f)
    topic_config = config["topic"]
    admin=AdminClient({
        "bootstrap.servers": config["bootstrap_servers"],
    })

    topic = NewTopic(
        topic=topic_config["name"],
        num_partitions=int(topic_config["partitions"]),
        replication_factor=int(topic_config["replication_factor"]),
        config={
            "retention.ms": str(topic_config["retention_ms"]),
            "cleanup.policy": topic_config["cleanup_policy"],
        },
    )

    futures = admin.create_topics([topic])

    for topic_name, future in futures.items():
        try:
            future.result()
            print(f"created topic={topic_name}")
        except Exception as exc:
            if "already exists" in str(exc).lower():
                print(f"topic already exists={topic_name}")
            else: 
                raise

if __name__ == "__main__":
    main()